# Changelog (Archived)

These releases are so old now, we'd rather you did not use them! They are archived here for prosperity :smile:

[View Stable Releases](index.md){ .md-button .md-button--primary }
[View Beta Releases](beta.md){ .md-button .md-button--primary }

## [v0.7.2] - 2021-01-26
[![Documentation Status](https://readthedocs.org/projects/dbtvault/badge/?version=v0.7.2)](https://dbtvault.readthedocs.io/en/v0.7.2/?badge=v0.7.2)

### New

- Derived columns can now be provided lists, for creating composite column values. [(#20)](https://github.com/Datavault-UK/dbtvault/issues/20)
  [Docs](../macros/index.md#stage-macro-configurations)
  
- The hashed_columns exclude flag in staging can now be provided without a list of columns, and dbtvault will hash everything. [Docs](../macros/index.md#stage-macro-configurations)

- Rank Load Materialisation: Iteratively load your vault structures over a configured ranking [Read More](../materialisations.md#vault_insert_by_rank-insert-by-rank)

- The stage macro now has a new `ranked_columns` configuration section to support the above materialisation. [Read More](../macros/index.md#stage-macro-configurations)

### Improved

- Optimised Satellite SQL for larger loads (billions) seen in the wild. 
- For non-hashdiff composite hashed_columns: If all components of the key are NULL, then the whole key will evaluate as NULL. 
  [Read more](../best_practises/hashing.md#how-do-we-hash)
- Hashing concatenation now uses `CONCAT_WS` instead of `CONCAT`; this is more concise.
- The stage macro has received a big overhaul, and the SQL should now be more efficient and easier to read.
- Optimised table macro SQL across to board by reducing the number of CTEs

### Fixed

- Fixed multiple (minor) bugs in the stage macro [(#21)](https://github.com/Datavault-UK/dbtvault/issues/21)
- Fixed and improved the `adapter.dispatch` implementation [(#22)](https://github.com/Datavault-UK/dbtvault/issues/22)
- Fixed a bug in the vault_insert_by_period materialisation [(#19)](https://github.com/Datavault-UK/dbtvault/issues/19)

### Docs

- Added examples of different ways to provide metadata to the [metadata reference](../metadata.md)
- Added a short guide on [extending dbtvault](../extending.md)
- Updated all SQL snippets to reflect changes

## [v0.7.1] - 2020-12-18
[![Documentation Status](https://readthedocs.org/projects/dbtvault/badge/?version=v0.7.1)](https://dbtvault.readthedocs.io/en/v0.7.1/?badge=v0.7.1)

### New

- **exclude_columns** flag for hashdiffs - Inverse the columns selected for creating a hashdiff to select ALL columns except those listed in the metadata.
This is very useful for large multi-column hashdiffs. 
  
!!! note

    See the new [stage macro configurations](../macros/index.md#stage-macro-configurations) section of the macro docs for more information on the change above.

### Improved

- The stage macro now generates CTE-based SQL instead of one big block. This makes it easier to read and debug. 
  See [here](https://discourse.getdbt.com/t/why-the-fishtown-sql-style-guide-uses-so-many-ctes/1091) for more information on why we've moved to CTEs.
  
- Multi-dispatch implementation now supports a package override variable, providing a smoother experience for 
users wishing to override macro implementations. Documentation will be made available in due course.
  See [Issue #14](https://github.com/Datavault-UK/dbtvault/issues/14) for more details.

- Hashed columns now 'see' columns defined as derived columns. Allowing you to use them in your hashed column definitions.
  [Issue #9](https://github.com/Datavault-UK/dbtvault/issues/9)

### Fixed

- Fixed a bug in the [vault_insert_by_period](../materialisations.md#vault_insert_by_period-insert-by-period) materialization which caused orphaned temporary relations 
  under specific circumstances. [Issue #18](https://github.com/Datavault-UK/dbtvault/issues/18)
  
- Stage macro conversion to CTE fixes [Issue #17](https://github.com/Datavault-UK/dbtvault/issues/17)

- dbt_utils dependency is now explicit [Issue #15](https://github.com/Datavault-UK/dbtvault/issues/15)

## [v0.7.0] - 2020-09-25
[![Documentation Status](https://readthedocs.org/projects/dbtvault/badge/?version=v0.7.0)](https://dbtvault.readthedocs.io/en/v0.7.0/?badge=v0.7.0)

### New

- Effectivity Satellites: A newly supported Data Vault 2.0 structure.  
[Read more](../tutorial/tut_eff_satellites.md)   
[Macro Reference](../macros/index.md#eff_sat) 

- Period Load Materialisation: Iteratively load your vault structures over a configured period [Read More](../materialisations.md#vault_insert_by_period-insert-by-period)
- dbt Docs: The built-in dbt docs site (`dbt docs serve`) now includes documentation for dbtvault*. 
- dbt v0.18.0 support [dbt v0.18.0 Release Notes](https://github.com/dbt-labs/dbt/releases/tag/v0.18.0)

!!! info
    *This is intended as quick reference and for completeness only, the online documentation is still the main reference documentation.
      
### Improved

- All table macros now make more use of CTEs to reduce nested SQL and improve readability and debugging potential. [Why CTEs?](https://discourse.getdbt.com/t/why-the-fishtown-sql-style-guide-uses-so-many-ctes/1091)
- All macros have had the licence header removed. This was a little messy and unnecessary.

### Removed

- Support for dbt versions prior to v0.18.0 [Upgrading to v0.18.0](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-0-18-0/)

## [v0.6.2] - 2020-08-06
[![Documentation Status](https://readthedocs.org/projects/dbtvault/badge/?version=v0.6.2)](https://dbtvault.readthedocs.io/en/v0.6.2/?badge=v0.6.2)

### Fixed

`dbt_project.yml`

`config-version: 1` caused an error in any dbt version prior to `0.17.x`. We only put this config
in for users making use of variables in their `dbt_project.yml` file. 

Note: If using `vars` in `dbt_project.yml`, you still need to specify `config-version: 1` in your own project's `dbt_project.yml`.
Guidance will be released for alternatives to model-scoped `dbt_project.yml` vars in the next major release of dbtvault (`0.7.x`)

Read more about the [config-version](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-0-17-0/) setting.

## [v0.6.1] - 2020-06-24
[![Documentation Status](https://readthedocs.org/projects/dbtvault/badge/?version=v0.6.1)](https://dbtvault.readthedocs.io/en/v0.6.1/?badge=v0.6.1)

### Added

- dbt 0.17.0 support 
**WARNING** This comes with a caveat that you must use `config-version: 1` in your `dbt_project.yml`

- All macros now support multiple dispatch. This update is to make way for additional platform support (BigQuery, Postgres etc.)

### Changed

- A hashdiff in the stage macro now uses `is_hashdiff` as a flag instead of `hashdiff`, 
this is to clarify this config option as a boolean flag.

### Improved
#### Macros
- Minor macro re-factors to improve readability

### Removed
#### Macros
- Cast macro (supporting) - No longer used. 
- Check relation (internal) - No longer used.

## [v0.6] - 2020-05-26
[![Documentation Status](https://readthedocs.org/projects/dbtvault/badge/?version=v0.6)](https://dbtvault.readthedocs.io/en/v0.6/?badge=v0.6)

**MAJOR UPDATE**

We've added a whole host of interesting new features.

[Read our v0.5 to v0.6 migration guide](https://dbtvault.readthedocs.io/en/v0.7.6/migration_guides/migrating_v0.5_v0.6/)

### Added

- Staging has now been moved to YAML format, meaning dbtvault is now entirely YAML and metadata driven.
See the new [stage](../macros/index.md#stage) macro and the [staging tutorial](../tutorial/tut_staging.md) for more details.

- Renamed `source` metadata configuration to `source_model` to clear up some confusion.
A big thank you to @balmasi for this suggestion.

- `HASHDIFF` aliasing is now available for Satellites
[Read More](https://dbtvault.readthedocs.io/en/v0.7.6/migration_guides/migrating_v0.5_v0.6/#hashdiff-aliasing)

### Upgraded

- [hub](../macros/index.md#hub) and [link](../macros/index.md#link) macros have been given a makeover.
They can now handle multi-day loads, meaning no more loading from single-date views.
We'll be updating the other macros soon, stay tuned!

### Fixed 

- Fixed `NULL` handling when hashing. We broke this in v0.5 ([see related issue](https://github.com/Datavault-UK/dbtvault/issues/5))
[Read more](../best_practises/hashing.md#how-do-we-hash)

### Removed

- Deprecated macros (old table template macros) 
- A handful of now unused internal macros
- Documentation website from main repository (this makes the package smaller!) 
[New docs repo](https://github.com/Datavault-UK/dbtvault-docs)

## [v0.5] - 2020-02-24

### Added

- Metadata is now provided in the `dbt_project.yml` file. This means metadata can be managed in one place. 
Read [Migrating from v0.4](https://dbtvault.readthedocs.io/en/v0.7.6/migration_guides/migrating_v0.4_v0.5/) for more information.

### Removed

- Target column metadata mappings are no longer required.
- Manual column mapping using triples to provide data-types and aliases (messy and bad practice).
- Removed copyright notice from generated tables (we are open source, duh!)

### Fixed

- Hashing a single column which contains a `NULL` value now works as intended (related to: [hash](../macros/index.md#hash-macro), 
_**multi_hash**_, [staging](../macros/index.md#staging-macros)).   

## [v0.4.1] - 2020-01-08

### Added

- Support for dbt v0.15

## [v0.4] - 2019-11-27

### Added

- Table Macros:
    - Transactional Links

### Improved

- Hashing:
    - You may now choose between `MD5` and `SHA-256` hashing with a simple yaml configuration
    [Learn how!](../best_practises/hashing.md#choosing-a-hashing-algorithm-in-dbtvault)
    
### Worked example

- Transactional Links
    - Added a Transactional Link model using a simulated transaction feed.
    
### Documentation

- Updated macros, best practices, roadmap, and other pages to account for new features
- Updated worked example documentation
- Replaced all dbt documentation links with links to the 0.14 documentation as dbtvault
is using dbt 0.14 currently (we will be updating to 0.15 soon!)
- Minor corrections

## [v0.3.3-pre] - 2019-10-31

### Documentation

- Added full demonstration project/worked example, using snowflake. 
- Minor corrections

## [v0.3.2-pre] - 2019-10-28

### Bug Fixes

- Fixed a bug where the logic for performing a base-load (loading for the first time) on a union-based Hub or Link was incorrect, causing a load failure.

### Documentation

- Various corrections and clarifications on the macros page.

## [v0.3.1-pre] - 2019-10-25

### Error handling

- An exception is now raised with an informative message when an incorrect source mapping is 
provided for a model in the case where a source relation is also provided for a target mapping. 
This caused missing columns in generated SQL, and a misleading error message from dbt. 

## [v0.3-pre] - 2019-10-24

### Improvements

- We've removed the need to specify full mappings in the `tgt` metadata when creating table models.
Users may now provide a table reference instead, as a shorthand way to keep the column name 
and date type the same as the source.
The option to provide a mapping is still available.

- The check for whether a load is a union load or not is now more reliable.

### Documentation

- Updated code samples and explanations according to new functionality
- Added a best practices page
- Various clarifications added and errors fixed

## [v0.2.4-pre] - 2019-10-17

### Bug Fixes

- Fixed a bug where the target alias would be used instead of the source alias when incrementally loading a Hub or Link,
causing subsequent loads after the initial load, to fail.

## [v0.2.3-pre] - 2019-10-08

### Macros

- Updated _**hash**_ and _**multi-hash**_
    - _**hash**_ now accepts a third parameter, `sort`
    which will alpha-sort provided columns when set to true.
    - _**multi-hash updated**_ to take advantage of
    the _**hash**_ functionality.

### Documentation

- Updated _**hash**_ and _**multi-hash**_ according to new changes.

## [v0.2.2-pre]  - 2019-10-08

### Documentation

- Finished Satellite page
- Added Union sections to Hub and Link pages
- Updated staging page with Satellite fields
- Renamed `stg_orders_hashed` back to `stg_customers_hashed`

## [v0.2.1-pre] - 2019-10-07

### Documentation

- Minor additions and corrections to documentation:
    - Fixed website URL in footer
    - Added contribution page to docs
    - Corrected version in dbt_project.yml

## [v0.2-pre] - 2019-10-07
 
### Improved
Read the linked documentation for more detail on how to take advantage of
the new and improved features.

- Table Macros:
    - All table macros now no longer require the `tgt_cols` parameter.
    This was unnecessary duplication of metadata and removing this now makes
    creating tables much simpler.
    
- Supporting Macros:
    - _**add_columns**_
        - Simplified the process of adding constants.
        - Can now optionally provide a [dbt source](https://docs.getdbt.com/docs/using-sources) to automatically
        retrieve all source columns without needing to type them all manually.
        - If not adding any calculated columns or constants, column pairs can be omitted, enabling you to provide the 
        source parameter above only.
    - _**hash**_ now alpha-sorts columns prior to hashing, as
    per best practices. 
   
- Staging Macros:
    - staging_footer renamed to _**from**_ and functionality for adding constants moved to _**add_columns**_
    - multi-hash
        - Formatting of output now more readable
        - Now alpha-sorts columns prior to hashing, as
          per best practices. 

## [v0.1-pre] - 2019-09 / 2019-10

### Added

- Table Macros:
    - Hub
    - Link
    - Satellite

- Supporting Macros:
    - cast
    - hash (renamed from md5_binary)
    - prefix

- Staging Macros:
    - add_columns
    - multi_hash (renamed from gen_hashing)
    - staging_footer

### Documentation
   
- Numerous changes for version 0.1 release

--8<-- "includes/abbreviations.md"
