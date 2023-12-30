# Variable guide

For non-derived variables, please see the NHANES documentation for [DEMO_D.csv](https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/DEMO_D.htm) and [FFQRAW_D.csv](https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/FFQRAW_D.htm) datasets. Derived variables are defined as follows:

### Index variables:

`fruit_index`, `veg_index` and `sugar_index ` variables were taken by summing all non-missing values of fruit, vegetable and sugar-related food products (respectively) for each respondent and dividing by the count of non-missing values for each respondent. 

For example, a respondent who reports consuming a given vegetable at frequency-level '5', another vegetable at frequency-level '6' - with the rest being 'missing' - would have a vegetable index score of '5.5'.


See FFQRAW_D documentation for details on these frequency levels.


### Consumption frequency variables:

These binary variables (e.g. `fruit_1`, `sugar_9`) are all intended to capture the proportion of respondents who consume fruit, vegetables and high-sugar products at a given frequency level. These variables contain either "Yes" or "No" for each respondent, but are constructed slightly differently between fruit/vegetables and sugar.

_Fruit/vegetables:_

These variables suggest whether the respondent has consumed a fruit no more than that frequency level. For example, a respondent with a value of "Yes" for `veg_6` has reported consuming a vegetable no more often than frequency level 6. A respondent recording a "Yes" for `fruit_1` has consumed no fruit more often than frequency level 1, or "never".

_Sugar:_

For high-sugar products, these variables instead depict whether the respondent has consumed _any_ high-sugar item at that frequency level or greater. For example, a respondent with a value of "Yes" for `sugar_10` would have reported consuming any high-sugar product at frequency level 10 or greater.