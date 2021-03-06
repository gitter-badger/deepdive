---
layout: default
title: FAQ
---

# DeepDive FAQ


### How can I debug my extractors?

See [debugging extractors](extractors.md#debug_extractors) section in extractor documentation.

### Can I have features for dictionary entries with precise terms (e.g.,
Cretaceous), and less-precise terms (e.g., Recent, Word)?

We suggest that you separate them into two features or inference rules, so that
DeepDive can learn the weight for each dictionary and choose the one to trust.

### If I have two inference rules with the same weight formula, will they share
the same weights?

No, weights are unique within each inference rule, this is achieved in DeepDive
by concating a ''prefix'' to the
feature, which by default is the name of the corresponding rule. You can force
the sharing of weights by specifying this
prefix, for example:

```bash
rule1 {
  weight       : ?(relation.someField)
  weightPrefix : "myPrefix"
}
rule2 {
  weight       : ?(relation.someField)
  weightPrefix : "myPrefix"
}
```

### I am getting a "java.lang.UnsupportedClassVersionError" error. What can I do?

This happens when you are using an older JRE version not supprted by DeepDive.
Make sure you are using JRE version 1.7.0\_45 or greater.


### I am using Greenplum, and getting an "ERROR: Cannot parallelize an UPDATE
statement that updates the distribution columns"

You should add a `DISTRIBUTED BY` clause in all `CREATE TABLE` commands. Make
sure you distribute your tables in a correct way: do not use the column `id` as
distribution key. Do not use a distribution key that is not initially assigned.


### I am using a `plpy_extractor` and I get  "ERROR: could not access file
"$libdir/plpython2": No such file or directory"

Make sure your database server supports the PL/python language.

### During sampling, I get an "error while loading shared libraries: libnuma.so.1"

Make sure you have configured the dependencies of the DimmWitted
[sampler](sampler.md) and that you properly set the necessary environmental
variables. Refer to the [Installation guide](installation.md#sampler) for
details.

