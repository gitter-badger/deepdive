---
layout: default
title: Running an Application
---

# Running a DeepDive application

This document describes how to run a DeepDive application, how to query the
results of the analysis, and how to define *pipelines* to select a subset of
extractor and/or inference rules to run.

This document assumes that DeepDive is installed and the database server is
running. See the [Installation guide](installation.md) for details.

We refer the interested reader to the ["Writing a new
application"](writing.md) document or to the
[Walktrough](walkthrough.md) for details about writing DeepDive
applications.


## Running
<!-- TODO This section overlaps too much with tutorial. Should be removed perhaps? -->

Running an application is as simple as running the following command under the application directory:

```bash
deepdive run
```

### Example

As an example we now show how to run the built-in spouse\_example application.
This example uses a news articles dataset. The articles are in plain text
format. The goal of the application is to extract spouse relationships between
individuals from the raw text of the articles. In other words, we want DeepDive
to compute information that can help us determining who is married to who.

To get a copy of the spouse example, first run the following command:

```bash
bash <(curl -fsSL deepdive.stanford.edu/install) deepdive_examples_tests
```

All examples in the last DeepDive release will be downloaded to a `deepdive-VERSION` directory.
Start by entering the spouse\_example directory:

```bash
cd deepdive-*/examples/spouse_example/postgres/tsv_extractor
```

The data resides in the `data/` subdirectory. The news articles are in the
`data/articles_dump.csv` file. Have a look at this file to get a rough idea
on what data DeepDive is processing.

For this example run, we use the `tsv_extractor` extractor.
Other extractors like `piggy_extractor`, `json_extractor`, and
`plpy_extractor` can also be found in the application directory. For more
details on extractors, see the ["Writing extractors"](extractors.md) document.

```bash
deepdive initdb
deepdive run
```

The first command sets up the database `deepdive_spouse_default` and the second runs the
application. The application takes about 100 seconds to complete. If the
execution completes with success, the output will look like the following:

    13:05:28 [profiler] INFO  --------------------------------------------------
    13:05:28 [profiler] INFO  Summary Report
    13:05:28 [profiler] INFO  --------------------------------------------------
    13:05:28 [profiler] INFO  ext_clear_table SUCCESS [137 ms]
    13:05:28 [profiler] INFO  ext_people SUCCESS [7087 ms]
    13:05:28 [profiler] INFO  ext_has_spouse_candidates SUCCESS [6444 ms]
    13:05:28 [profiler] INFO  ext_has_spouse_features SUCCESS [37349 ms]
    13:05:28 [profiler] INFO  inference_grounding SUCCESS [34316 ms]
    13:05:28 [profiler] INFO  inference SUCCESS [14779 ms]
    13:05:28 [profiler] INFO  calibration plot written to .../calibration/has_spouse.is_true.png [0 ms]
    13:05:28 [profiler] INFO  calibration SUCCESS [1133 ms]
    13:05:28 [profiler] INFO  --------------------------------------------------
    13:05:28 [taskManager] INFO  Completed task_id=report with Success(Success(()))
    13:05:28 [taskManager] INFO  1/1 tasks eligible.
    13:05:28 [taskManager] INFO  Tasks not_eligible: Set()
    [success] Total time: 103 s, completed Jun 23, 2014 1:05:28 PM

## <a name="results" href="#"></a> Results

DeepDive stores all the results in the application database. For our example
application, this is the `deepdive_spouse_default` database.

For each query variable, DeepDive generates a view called
`[TABLE]_[VARIABLE_NAME]_inference`, which contains the original data, augmented
with a `expectation` column, which is the result of the inference step.

For example, the `has_spouse_is_true_inference` has the
following schema:

     View "public.has_spouse_is_true_inference"

       Column    |       Type       | Modifiers
    -------------+------------------+-----------
     person1_id  | bigint           |
     person2_id  | bigint           |
     sentence_id | bigint           |
     description | text             |
     is_true     | boolean          |
     relation_id | bigint           |
     id          | bigint           |
     category    | bigint           |
     expectation | double precision |

To inspect the results, it is sufficient to run a query on this table. The
following example query would return some of the marriage relationships that
have probability more than 0.9 to be true:

```bash
deepdive sql "
  SELECT description, expectation
  FROM has_spouse_is_true_inference
  WHERE expectation > 0.9 and expectation < 1
  ORDER BY random() LIMIT 5;
"
```

The output is formatted as 'person1-person2' like in the following example:

      description   | expectation
    ----------------+-------------
     Obama-Michelle |       0.982

This means that 'Obama' is married to 'Michelle' with probability of 0.982.

The learned weights for the factors are stored in the table
`dd_inference_results_weights`. DeepDive creates a view called
`dd_inference_result_mapped_weights` which contains the feature and the
learned values sorted by absolute value.

Calibration plots allow to evaluate the quality of the results. For more details
about inspecting the learned weights and using calibration plots, see the
[Calibration guide](calibration.md).

## <a name="pipelines" href="#"></a> Pipelines

DeepDive allows to define *pipelines* to specify which extractors and inference
rules are active and should be executed. This is useful for debugging purposes.

You can define custom pipelines by adding the following configuration directives:

    deepdive {
      pipeline.run: myPipeline
      pipeline.pipelines { myPipeline: [ extractor1 extractor2 inferenceRule1 ] }
    }

Refer to the [configuration reference](configuration.md#pipelines) for details
about the syntax of these directives.

When the `pipeline.run` directive is not specified, DeepDive executes all
extractors and inference rules.
The pipeline name can be specified as an argument to the `deepdive run` command.

You can set `pipeline.relearn_from` to an output directory of a previous
execution of DeepDive to use an existing factor graph for learning and
inference:

    deepdive {
      pipeline.relearn_from: "/path/to/your/app/run/LATEST/"
    }

In this case DeepDive would skip all extractors. This could be useful for tuning
the sampler parameters.

