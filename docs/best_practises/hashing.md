!!! seealso "See Also"
    - [hash](../macros/index.md#hash-macro)
    - [hash_columns](../macros/stage_macro_configurations.md#hashed-columns)
 
### The drawbacks of using MD5

By default, dbtvault uses MD5 hashing to calculate hashes using [hash](../macros/index.md#hash-macro)
and [hash_columns](../macros/stage_macro_configurations.md#hashed-columns). If your table contains more than a few billion rows, then there is a chance
of a clash: where two different values generate the same hash value
(see [Collision vulnerabilities](https://en.wikipedia.org/wiki/MD5#Collisi76on_vulnerabilities)).

For this reason, it **should not be** used for cryptographic purposes either.

You can however, choose between MD5 and SHA-256 in
dbtvault, [read below](#choosing-a-hashing-algorithm-in-dbtvault), which will help with reducing the
possibility of collision in larger data sets.

#### Personally Identifiable Information (PII)

Although we do not use hashing for the purposes of security (but rather optimisation and uniqueness) using _unsalted_
MD5 and SHA-256 could still pose a security risk for your organisation. If any of your presentation layer (marts) tables
or views containing any hashed PII data, an attacker may be able to brute-force the hashing to gain access to the PII.
For this reason, we highly recommend concatenating a _salt_ to your hashed columns in the staging layer using
the [stage](../macros/index.md#stage) macro.

It's generally ill-advised to store this salt in the database alongside your hashed values, so we recommend injecting it
as an environment variable for dbt to access via
the [env_var jinja context macro](https://docs.getdbt.com/docs/writing-code-in-dbt/jinja-context/env_var/).

This salt **must** be a constant, as we still need to ensure that the same value produces the same hash each and every
time so that we may reliably look-up and reference hashes. The salt could be an (initially) randomly generated 128-bit
string, for example, which is then never changed and stored securely in a secrets manager.

In the future, we plan to develop a helper macro for achieving these salted hashes, to cater to this use case.

### Why do we hash?

Data Vault uses hashing for two different purposes.

#### Primary Key Hashing

A hash of the primary key. This creates a surrogate key, but it is calculated consistently across the database:
as it is a single column, same data type, it supports pattern-based loading.

#### Hashdiffs

Used to finger-print the payload of a Satellite (similar to a checksum), so that it is easier to detect if there has
been a change in the payload. This triggers the load of a new Satellite record. This simplifies the SQL as otherwise
we'd have to compare each column in turn and handle nulls to see if a change had occurred.

Hashing is sensitive to column ordering. If you provide the `is_hashdiff: true` flag to your column specification in
the [stage](../macros/index.md#stage) macro, dbtvault will automatically sort the provided columns alphabetically. Columns will
be sorted by their alias.

### How do we hash?

Our hashing approach has been designed to standardise the hashing process, and ensure hashing has been kept consistent
across a data warehouse.

#### Single-column hashing

When we hash single columns, we take the following approach:

```sql 
CAST((MD5_BINARY(NULLIF(UPPER(TRIM(CAST(BOOKING_REF AS VARCHAR))), ''))) AS BINARY(16)) AS BOOKING_HK
```

Single-column hashing step by step:

1. `CAST` to `VARCHAR` First we ensure that all data gets treated the same way in the next steps by casting everything
   to strings (`VARCHAR`). For example, this means that the number 1001, and the string '1001' will always hash to the
   same value.

2. `TRIM` We trim whitespace from string to ensure that values with arbitrary leading or trailing whitespace will always
   hash to the same value. For example <code>1001&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</code> and <code>&nbsp;1001</code>.

3. `UPPER` Next we eliminate problems where the casing in a string will cause a different hash value to be generated for
   the same word, for example `DBTVAULT` and `dbtvault`.

4. `NULLIF ''` At this point we ensure that if an empty string has been provided, it will be considered `NULL`. This
   kind of problem can arise if data gets ingested into your warehouse from semi-structured data such as JSON or CSV,
   where `NULL` values can sometimes be encoded as empty strings.

5. `MD5_BINARY` At this point, we are ready to perform a hashing process on the string, having cleaned and normalised
   it. This will not necessarily use `MD5_BINARY` if you have chosen to use `SHA`, in which case the `SHA2_BINARY`
   function will be used.

6. `CAST AS BINARY` We then store it as a `BINARY` datatype

#### Multi-column hashing

When we hash multiple columns, we take the following approach:

=== "Multi Column Hashing"

    === "Non-Hashdiff"

        ```sql 
        CAST(MD5_BINARY(NULLIF(CONCAT_WS('||', 
            IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'),
            IFNULL(NULLIF(UPPER(TRIM(CAST(DOB AS VARCHAR))), ''), '^^'),
            IFNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR))), ''), '^^')
        ), '^^||^^||^^')) AS BINARY(16)) AS CUSTOMER_HK
        ```

    === "Hashdiff"
    
        ```sql 
        CAST(MD5_BINARY(CONCAT_WS('||',
            IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '^^'),
            IFNULL(NULLIF(UPPER(TRIM(CAST(DOB AS VARCHAR))), ''), '^^'),
            IFNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR))), ''), '^^')
        )) AS BINARY(16)) AS HASHDIFF
        ```

This is similar to single-column hashing aside from the use of `IFNULL` and `CONCAT`. The step-by-step process has been
described below.

1\. Steps 1-4 are described in single-column hashing above and are performed on each column which comprises the
multi-column hash.

5\. `IFNULL` If Steps 1-4 resolve in a NULL value (in the case of the empty string, or a true `NULL`),
then we output a double-hat string `^^` by default. This ensures that we can detect changes in columns between `NULL` and
non-`NULL` values. This is particularly important for `HASHDIFFS`.

5.5\. `NULLIF` When `is_hashdiff = false` and multiple columns get hashed, an extra `NULLIF` check gets executed. This
is to ensure that if ALL components of a composite hash key are `NULL`, then the whole key evaluates as `NULL`. When
loading Hubs, for example we do not want to load NULL records and if we evaluate the whole key as `NULL`, then we
resolve this issue.

6\. `CONCAT_WS` Next, we concatenate the column values using a double-pipe string, `||`, by default. This ensures we have consistent
concatenation, using a string which is unlikely to be contained in the columns we are concatenating. Concatenating in
this way means that we can be more confident that a combination of columns will always generate the same hash value,
particularly where `NULLS` are concerned.

7\. Steps 7 and 8 are identical to steps 5 and 6 described in single-column hashing.

### Hashdiff components

As per Data Vault 2.0 Standards, `HASHDIFF` columns should contain the natural key (the column(s) a PK/HK is calculated
from)
of the record, and the payload of the record.

!!! note

    Prior to dbtvault v0.7.4 hashdiffs are **REQUIRED** to contain the natural keys of the record. 
    In dbtvault v0.7.4, macros have been updated to include logic to ensure the primary key is checked
    in addition to the hashdiff when detecting new records. It is still best practice to include the natural keys, however. 

### Hashing best practices

Best practices for hashing include:

- Alpha sorting Hashdiff columns. As mentioned, dbtvault can do this for us, so no worries!
  Refer to the [stage](../macros/index.md#stage) docs for details on how to do this.

- Ensure all **Hub** columns used to calculate a primary key hash get presented in the same order across all staging
  tables

!!! note 

    Some tables may use different column names for primary key components, so you generally **should not** use the
    sorting functionality for primary keys.

- For **Links**, columns must be sorted by the primary key of the Hub and arranged alphabetically by the Hub name. The
  order must also be the same as each Hub.

### Hashdiff Aliasing

`HASHDIFF` columns should be called `HASHDIFF`, as per Data Vault 2.0 standards. Due to the fact we have a shared
staging layer for the raw vault, we cannot have multiple columns sharing the same name. This means we have to name each
of our `HASHDIFF` columns differently.

Below is an example satellite YAML config from a Satellite model:

=== "sat_customer_details"

    ```yaml hl_lines="4 5 6"
    {%- set yaml_metadata -%}
    source_model: stg_customer_details_hashed
    src_pk: CUSTOMER_HK
    src_hashdiff: 
      source_column: CUSTOMER_HASHDIFF
      alias: HASHDIFF
    src_payload:
      - NAME
      - ADDRESS
      - PHONE
      - ACCBAL
      - MKTSEGMENT
      - COMMENT
    src_eff: EFFECTIVE_FROM
    src_ldts: LOAD_DATETIME
    src_source: RECORD_SOURCE
    {%- endset -%}
    ```

The highlighted lines show the syntax required to alias a column named `CUSTOMER_HASHDIFF` (present in the
`stg_customer_details_hashed` staging layer) as `HASHDIFF`.

### Choosing a hashing algorithm in dbtvault

You may choose between `MD5` and `SHA-256` hashing. `SHA-256` is an option for users who wish to reduce the hashing
collision rates in larger data sets.

!!! note

    If a hashing algorithm configuration is missing or invalid, dbtvault will use `MD5` by default. 

Configuring the hashing algorithm which will be used by dbtvault is simple: add a global variable to your
`dbt_project.yml` as follows:

=== "dbt_project.yml"

    ```yaml
    
    name: 'my_project'
    version: '1'
    
    profile: 'my_project'
    
    source-paths: [ "models" ]
    analysis-paths: [ "analysis" ]
    test-paths: [ "tests" ]
    data-paths: [ "data" ]
    macro-paths: [ "macros" ]
    
    target-path: "target"
    clean-targets:
      - "target"
      - "dbt_modules"
    
    vars:
      hash: SHA # or MD5
    ```

It is possible to configure a hashing algorithm on a model-by-model basis using the hierarchical structure of the `yaml`
file. We recommend you keep the hashing algorithm consistent across all tables, however, as per best practice.

Read the [dbt documentation](https://docs.getdbt.com/reference/dbt-jinja-functions/var) for further information on
variable scoping.

!!! warning

    Stick with your chosen algorithm unless you can afford to full-refresh, and you still have access to source
    data. Changing between hashing configurations when data has already been loaded will require a full-refresh of your
    models in order to re-calculate all hashes.

### Configuring hash strings

As previously described, the **_default_** hashing strings are as follows:

`concat_string` is `||`

`null_placeholder_string` is `^^`

The strings can be changed by the user, and this is achieved in the same way as configuring the hashing algorithm:

=== "dbt_project.yml hash string configuration"

    ```yaml
    
    ...
    vars:
      concat_string: '!!'
      null_placeholder_string: '##'  
    ```

=== "Result (Multi Column Hashing with custom strings)"

    ```sql 
    CAST(MD5_BINARY(NULLIF(CONCAT_WS('!!', 
        IFNULL(NULLIF(UPPER(TRIM(CAST(CUSTOMER_ID AS VARCHAR))), ''), '##'),
        IFNULL(NULLIF(UPPER(TRIM(CAST(DOB AS VARCHAR))), ''), '##'), '!!',
        IFNULL(NULLIF(UPPER(TRIM(CAST(PHONE AS VARCHAR))), ''), '##')
    ), '##!!##!!##')) AS BINARY(16)) AS CUSTOMER_HK
    ```

### The future of hashing in dbtvault

We plan to provide users with the ability to disable hashing entirely.

The intent behind our hashing approach is to provide a robust method of ensuring consistent hashing (same
input gives same output). Until we provide more configuration options, feel free to modify our macros for your needs, as
long as you stick to a standard that makes sense to you or your organisation. If you need
advice, [feel free to join our slack and ask our developers](https://join.slack.com/t/dbtvault/shared_invite/enQtODY5MTY3OTIyMzg2LWJlZDMyNzM4YzAzYjgzYTY0MTMzNTNjN2EyZDRjOTljYjY0NDYyYzEwMTlhODMzNGY3MmU2ODNhYWUxYmM2NjA)!

