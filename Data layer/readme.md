# Final Data Layer

Pathways utilizes publicly recognized data, such as that from the Demographic and Health Surveys (DHS), whose quality, completeness, and structure facilitate data preparation and population segmentation.

After designing the segmentation process, it has been implemented in data pipelines using cutting-edge technologies, which prepare the results for availability on the online platform.

Even so, in certain specific cases, the variables from the DHS (or another sources) used within the segmentation algorithms have a nature that makes them difficult to interpret when ultimately presented in reports intended for end users. These reports, which present metrics classified according to their type (outcomes and vulnerabilities), require that each possible value for the metric or indicator allow for clear interpretation by the end user, who is not necessarily always a data analyst, but could also be a public health policymaker, or a designer using these results to design an intervention in the field, directly with the populations.

Therefore, for some variables, it will be necessary to perform final transformation processes, mainly inverting their value (e.g. from 0 to 1 or vice versa) or combining values, so that the health metric associated with the variable is easily understandable and free of ambiguities.

This collection of examples shows the three most common types of transformations and presents some code examples in the attached scripts:

* [Part 1: Skip pattern handles](Skip%20patterns%20handle.md)
* [Part 2: Simple outcome inversions handling](Simple%20outcome%20inversions%20handling.md)
* [Part 3: Complex inversions and aggregation logic](Complex%20inversions%20and%20aggregation%20logic.md)
