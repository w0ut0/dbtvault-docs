All raw vault structures support both the built-in dbt incremental materialisation and
dbtvault's [custom materialisations](materialisations.md).

[Read more about incremental models](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/)

### Table and View

dbtvault macros do not support Table or View materialisations. You will be able to create your models if these
materialisations are set, however they will behave unpredictably. We have no plans to support these materialisations, as
they fundamentally break and oppose Data Vault 2.0 standards (i.e. are not insert-only)

### Recommended Materialisations

!!! seealso "See Also"
    - [bridge_incremental](../materialisations.md#bridge_incremental)
    - [pit_incremental](../materialisations.md#pit_incremental)

| Structure                    | incremental      | bridge_incremental | pit_incremental    |
|------------------------------|------------------|--------------------|--------------------|
| Hub                          | :material-check: |                    |                    |
| Link                         | :material-check: |                    |                    |
| Transactional Link           | :material-check: |                    |                    |
| Satellite                    | :material-check: |                    |                    |
| Effectivity Satellite        | :material-check: |                    |                    |
| Multi-Active Satellite       | :material-check: |                    |                    |
| Extended Tracking Satellites | :material-check: |                    |                    |
| Bridge Tables                |                  | :material-check:   |                    |
| Point In Time Tables         |                  |                    | :material-check:   |