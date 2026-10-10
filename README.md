# cdk diff misses an added key in a JSON string built with intrinsics

Since aws-cdk CLI 2.1129.0, `cdk diff` (default `--method=auto`) reports
"There were no differences" when a string property holds JSON containing an
intrinsic (`Ref`/`Fn::*`) and the change only adds a key. `cdk deploy` still
applies the change and `--method=template` shows it.

The JSON string is what `Stack.to_json_string()` produces, and what
`aws-eks` uses for `KubernetesManifest`/`HelmChart` properties. Adding a field
to a Kubernetes manifest (e.g. a new annotation) is invisible in the diff.

| CLI version | Result                  |
|-------------|-------------------------|
| 2.1128.1    | shows the change        |
| 2.1129.0    | "no differences"        |
| 2.1145.0    | "no differences"        |

## Repro

```sh
uv sync
cdk deploy
cdk diff -c add_key=true                   # no differences
cdk diff -c add_key=true --method=template # shows the added key
npx aws-cdk@2.1128.1 diff -c add_key=true  # shows the added key
cdk destroy
```

`app.py` deploys one `AWS::SSM::Parameter` whose value is
`{"stack":"<AWS::StackName>","a":"1"}`; `-c add_key=true` adds `"b":"2"`.

## Cause

1. CloudFormation: `DescribeChangeSet` with `IncludePropertyValues=true`
   omits a resource whose JSON string property only gains an object key. The
   change set is `CREATE_COMPLETE` with `"Changes": []` and no warning. Without
   `IncludePropertyValues` the same change set reports `Modify Param`.
   Removing a key, changing a value, appending to an array, or a non-JSON edit
   are all reported. `cfn/repro.sh` shows this with plain CloudFormation and a
   static value, no CDK involved.
2. aws-cdk-cli: 2.1129.0 (#1668) started describing diff change sets with
   `IncludePropertyValues`. The merger then marks template differences on
   resources missing from the change set as no-change. #1951 keeps static
   differences, and #1785 re-describes without property values when
   CloudFormation emits a warning. Neither applies here: the value contains
   `Ref`, and CloudFormation emits no warning.
