Hubs are one of the core building blocks of a Data Vault. Hubs record a unique list of all business keys for a single entity. 
For example, a Hub may contain a list of all Customer IDs in the business. 

### Watch the video

Prefer a video? This video has a great overview of the content on this page.
    
<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/DDc0hS_XCpo" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Structure

In general, Hubs consist of 4 columns, described below.

#### Primary Key (src_pk)
A primary key (or surrogate key) which is usually a hashed representation of the natural key.

#### Natural Key / Business Key (src_nk)
This is usually a formal identification for the record, such as a customer ID or 
order number. Usually called the business key because this value has meaning in
business processes such as transactions and events.

#### Load date (src_ldts)
A load date or load date timestamp. This identifies when the record was first loaded into the database.

#### Record Source (src_source)
The source for the record. This can be a code which is assigned to a source name in an external lookup table, 
or a string directly naming the source system.
(i.e. `1` from the [staging section](tut_staging.md#adding-the-metadata), 
which is the code for `stg_customer`)

### Creating Hub models

Create a new dbt model as before. We'll call this one `hub_customer`. 

=== "hub_customer.sql"

    ```jinja
    {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
    ```

To create a Hub model, we simply copy and paste the above template into a model named after the Hub we
are creating. dbtvault will generate a Hub using parameters provided in the next steps.

#### Materialisation

The recommended materialisation for **Hubs** is `incremental`, as we load and add new records to the existing data set.

### Adding the metadata

Let's look at the metadata we need to provide to the [hub macro](../macros/index.md#hub).

We provide the column names which we would like to select from the staging area (`source_model`).

Using our [knowledge](#structure) of what columns we need in our `hub_customer` Hub, we can identify columns in our
staging layer which map to them:

| Parameter    | Value         |
|--------------|---------------|
| source_model | v_stg_orders  |
| src_pk       | CUSTOMER_HK   |
| src_nk       | CUSTOMER_ID   |
| src_ldts     | LOAD_DATETIME |
| src_source   | RECORD_SOURCE |

When we provide the metadata above, our model should look like the following:

=== "hub_customer.sql"

    ```jinja
    {{ config(materialized='incremental')    }}
    
    {%- set source_model = "v_stg_orders"   -%}
    {%- set src_pk = "CUSTOMER_HK"          -%}
    {%- set src_nk = "CUSTOMER_ID"          -%}
    {%- set src_ldts = "LOAD_DATETIME"      -%}
    {%- set src_source = "RECORD_SOURCE"    -%}
    
    {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
    ```

!!! Note
    See our [metadata reference](../metadata.md#hubs) for more detail on how to provide metadata to Hubs.

### Running dbt

With our metadata provided and our model complete, we can run dbt to create our `hub_customer` Hub, as follows:

=== "< dbt v0.20.x"
    `dbt run -m +hub_customer`

=== "> dbt v0.21.0"
    `dbt run -s +hub_customer`

The resulting Hub table will look like this:

| CUSTOMER_HK | CUSTOMER_ID | LOAD_DATETIME           | SOURCE |
|-------------|-------------|-------------------------|--------|
| B8C37E...   | 1001        | 1993-01-01 00:00:00.000 | 1      |
| .           | .           | .                       | 1      |
| .           | .           | .                       | 1      |
| FED333...   | 1004        | 1993-01-01 00:00:00.000 | 1      |

### Loading hubs from multiple sources

In some cases, we may need to load Hubs from multiple sources, instead of a single source as we have seen so far.
This may be because we have multiple source staging tables, each of which contains a natural key for the Hub. 
This would require multiple feeds into one table: dbt prefers one feed, 
so we perform a union operation on the separate sources together and load them as one. 

The data can and should be combined because these records have a truly identical key (same business meaning).
The `hub` macro will perform a union operation to combine the tables using that key, and create a Hub containing
a complete record set.

The metadata needed to create a multi-source Hub is identical to a single-source Hub, we just provide a 
list of sources (usually multiple [staging areas](tut_staging.md)) rather than a single source, and the [hub](../macros/index.md#hub) macro 
will handle the rest:

!!! warning "Important"

    If your primary key and natural key columns have different names across the different
    tables, they will need to be aliased to the same name in the respective staging layers 
    via a `derived column` configuration, using the [stage](../macros/index.md#stage) macro in the staging layer.

#### Example

=== "Variable Metadata approach"
    ```jinja hl_lines="3-5"
    
    
    {{ config(materialized='incremental') }}
    
    {%- set source_model = ["v_stg_orders_web", 
                            "v_stg_orders_crm", 
                            "v_stg_orders_sap"]   -%}
    
    {%- set src_pk = "CUSTOMER_HK"                -%}
    {%- set src_nk = "CUSTOMER_ID"                -%}
    {%- set src_ldts = "LOAD_DATETIME"            -%}
    {%- set src_source = "RECORD_SOURCE"          -%}
    
    {{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
    ```

=== "YAML Metadata approach"

    ```jinja hl_lines="2-5"
    {%- set yaml_metadata -%}
    source_model: 
        - v_stg_orders_web
        - v_stg_orders_crm
        - v_stg_orders_sap
    src_pk: CUSTOMER_HK
    src_nk: CUSTOMER_ID
    src_ldts: LOAD_DATETIME
    src_source: RECORD_SOURCE
    {%- endset -%}
    
    {% set metadata_dict = fromyaml(yaml_metadata) %}
    
    {{ dbtvault.hub(src_pk=metadata_dict["src_pk"],
                    src_nk=metadata_dict["src_nk"], 
                    src_ldts=metadata_dict["src_ldts"],
                    src_source=metadata_dict["src_ldts"],
                    source_model=metadata_dict["source_model"]) }}
    ```

See the [Hub metadata reference](../metadata.md#hubs) for more examples.

--8<-- "includes/abbreviations.md"