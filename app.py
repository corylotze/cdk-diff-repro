import aws_cdk as cdk
from aws_cdk import aws_ssm as ssm

app = cdk.App()
stack = cdk.Stack(app, "CdkDiffRepro")

value = {"stack": cdk.Aws.STACK_NAME, "a": "1"}
if app.node.try_get_context("add_key") == "true":
    value["b"] = "2"

ssm.StringParameter(stack, "Param", string_value=stack.to_json_string(value))

app.synth()
