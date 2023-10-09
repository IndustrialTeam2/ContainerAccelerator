#!/usr/bin/env python3

from kubernetes import client, config
import boto3, hcl2, sys

### TEST FAILED EXCEPTION ###

class TestFailedException(BaseException):

    def __init__(self, *args: object) -> None:
        super().__init__(*args)

### TESTING FUNCTIONS ###
def __foo():
    pass

func_type = type(__foo)

__test_results = {}

def record_result(func_name: str, result):
    __test_results[func_name] = result

def pass_test(func: func_type, warning=''):
    record_result(func.__name__, {
        'result': 'pass' if warning == '' else 'warning',
        'reason': warning
    })

def fail_test(func: func_type, reason: str):
    record_result(func.__name__, {
        'result': 'fail',
        'reason': reason
    })

def show_test_results():

    fails = 0
    passes = 0
    warnings = 0

    print('FUNCTION\t\t\tRESULT\t\tREASON (IF ANY)\n')

    for (func_name,result) in __test_results.items():
        print(f'{func_name}\t\t{result["result"]}\t\t{result["reason"]}')

        if result['result'] == 'pass':
            passes += 1
        
        elif result['result'] == 'warning':
            passes += 1
            warnings += 1
        
        elif result['result'] == 'fail':
            fails += 1

    print(f'\n{passes} TESTS PASSED WITH {warnings} WARNINGS, {fails} FAILS')

    if fails > 0:
        raise TestFailedException()
    

# New tests should be written by the client when increasing complexity

def test_nodegroup_instance_types(instance_types_tf, instance_types_aws):
    """ Compare the instance types seen in our terraform file against
        the ones seen on AWS through their API
    """
    if sorted(instance_types_tf) == sorted(instance_types_aws):
        pass_test(test_nodegroup_instance_types)
    
    else:
        fail_test(test_nodegroup_instance_types, 'instance type mismatch')

def test_node_minimum_instances(minimum_tf, minimum_aws):
    """ Compare the minimum instances of a nodegroup seen in our terraform
        file against the one seen on AWS through their API
    """

    if minimum_tf == minimum_aws:
        pass_test(test_node_minimum_instances)

    else:
        fail_test(test_node_minimum_instances, 'minimum instances mismatch')

def test_node_desired_instances(desired_tf, desired_aws):
    """ Compare the desired instances of a nodegroup seen in our terraform
        file against the one seen on AWS through their API
    """

    if desired_tf == desired_aws:
        pass_test(test_node_desired_instances)

    else:
        fail_test(test_node_desired_instances, 'desired instances mismatch')

def test_node_maximum_instances(maximum_tf, maximum_aws):
    """ Compare the maximum instances of a nodegroup seen in our terraform
        file against the one seen on AWS through their API
    """

    if maximum_tf == maximum_aws:
        pass_test(test_node_maximum_instances)

    else:
        fail_test(test_node_maximum_instances, 'maximum instances mismatch')

### TF PARSING FUNCTIONS ###

def scrape_vars(vars_filename: str) -> dict:

    tf_vars = {}

    """
    .tf files take the form of:

    {
        variable: [
            {
                var1: {
                    description: blah,
                    type: string,
                    default: 'value'
                }
            },
            ...
        ]
    }

    .tfvars files take the form of:
    {
        var1: value1,
        var2: value2,
        ...
    }
    """

    with open(vars_filename, 'r') as vars_file:

        if vars_filename.endswith('.tf'):
            var_dicts = hcl2.load(vars_file)

            if var_dicts and var_dicts != {}:
                var_dicts = var_dicts['variable']

            for var_dict in var_dicts:

                key = list(var_dict)[0]
                value = var_dict[key]['default']

                tf_vars[key] = value

        elif vars_filename.endswith('.tfvars'):
            tf_vars = hcl2.load(vars_file)
        
    return tf_vars
    
### AWS PARSING FUNCTIONS ###

def parse_response(response: dict, expected_data_name=''):

    http_status_code = response['ResponseMetadata']['HTTPStatusCode']

    if http_status_code != 200:
        raise Exception(f'Got HTTP Status Code {http_status_code} (Expected 200).\
                        \nResponse metadata: {response["ResponseMetadata"]}')
    else:
        return response[expected_data_name]

def get_cluster_aws(eks_client, cluster_name: str) -> dict:

    response = eks_client.describe_cluster(name=cluster_name)

    return parse_response(response, 'cluster')

def get_cluster_nodegroup_names_aws(eks_client, cluster_name: str) -> dict:
    
    response = eks_client.list_nodegroups(clusterName=cluster_name)

    return parse_response(response, 'nodegroups')

def get_cluster_nodegroup_aws(eks_client, cluster_name, nodegroup_name):

    response = eks_client.describe_nodegroup(clusterName=cluster_name, nodegroupName=nodegroup_name)

    return parse_response(response, 'nodegroup')

### K8S PARSING FUNCTIONS ###

### MAIN ###

if __name__ == '__main__':

    # scrape your variables file

    variables_tf = scrape_vars('variables.tf')

    # extract variables like so:

    cluster_name_tf = variables_tf['cluster_name']

    nodegroup_instance_types_tf = variables_tf['node_group_instance_types']

    nodegroup_minimum_instances_tf = variables_tf['node_group_minimum_instances']
    nodegroup_desired_instances_tf = variables_tf['node_group_desired_instances']
    nodegroup_maximum_instances_tf = variables_tf['node_group_maximum_instances']

    # instantiate boto3 client [REQUIRES AWS CREDENTIALS SET UP]

    b3client = boto3.client('eks')

    # get resources through the AWS API

    cluster_aws = get_cluster_aws(b3client, cluster_name_tf)

    nodegroup_names_aws = get_cluster_nodegroup_names_aws(b3client, cluster_name_tf)

    nodegroups_aws = [get_cluster_nodegroup_aws(b3client, cluster_name_tf, name) for name in nodegroup_names_aws]

    nodegroup_instance_types_aws = {nodegroup['nodegroupName']: nodegroup['instanceTypes'] for nodegroup in nodegroups_aws}

    nodegroup_scaling_config_aws = {nodegroup['nodegroupName']: nodegroup['scalingConfig'] for nodegroup in nodegroups_aws}

    # perform configuration tests. 

    test_nodegroup_instance_types(nodegroup_instance_types_tf, nodegroup_instance_types_aws[nodegroup_names_aws[0]]) 

    test_node_minimum_instances(nodegroup_minimum_instances_tf, nodegroup_scaling_config_aws[nodegroup_names_aws[0]]['minSize'])

    test_node_desired_instances(nodegroup_desired_instances_tf, nodegroup_scaling_config_aws[nodegroup_names_aws[0]]['desiredSize'])

    test_node_maximum_instances(nodegroup_maximum_instances_tf, nodegroup_scaling_config_aws[nodegroup_names_aws[0]]['maxSize'])

    # show test results

    show_test_results()
    
    # close client after use [REQUIRED]
    b3client.close()
