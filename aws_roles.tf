resource "aws_iam_role" "eks_cluster_developer" {
  name = "eks_cluster_developer"

  assume_role_policy = jsonencode({
    "Version":  "2012-10-17"
    "Statement":  [{
      "Action": "sts:AssumeRole"
      "Effect": "Allow"
      "Principal": {
        "AWS" : "*"
      }
    }]
  })
}


resource "aws_iam_policy" "DeveloperAcccess" {
  name        = "DeveloperAcccess"
  description = "This policy allows the developer to deploy applications to the EKS cluster"

  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "eks:ListFargateProfiles",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:ListUpdates",
          "eks:AccessKubernetesApi",
          "eks:ListAddons",
          "eks:DescribeCluster",
          "eks:DescribeAddonVersions",
          "eks:ListClusters",
          "eks:ListIdentityProviderConfigs",
          "eks:TagResource",
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [

          "eks:DescribeFargateProfile",
          "eks:ListTagsForResource"
        ],
        "Resource" : "*"
      },

        {
            "Sid": "ViewOwnUserInfo",
            "Effect": "Allow",
            "Action": [
                "iam:GetUserPolicy",
                "iam:ListGroupsForUser",
                "iam:ListAttachedUserPolicies",
                "iam:ListUserPolicies",
                "iam:GetUser",
                "iam:GetRolePolicy",
                "iam:GetRole",
                "iam:GetPolicy",
                "iam:ListRolePolicies",
                "iam:ListRoles"
            ],
            "Resource": "*"
        },
        {
            "Sid": "NavigateInConsole",
            "Effect": "Allow",
            "Action": [
                "iam:GetGroupPolicy",
                "iam:GetPolicyVersion",
                "iam:GetPolicy",
                "iam:ListAttachedGroupPolicies",
                "iam:ListGroupPolicies",
                "iam:ListPolicyVersions",
                "iam:ListPolicies",
                "iam:ListUsers",
                "iam:ListAttachedRolePolicies",
                "iam:ListEntitiesForPolicy"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ViewLogs",
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:GetLogEvents",
                "logs:ListTagsLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Sid": "GetECR",
            "Effect": "Allow",
            "Action": [
                "ecr-public:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
         {
            "Sid": "EC2Describe",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeRegions",
                "ec2:DescribeVpcs",
                "ec2:DescribeVpcAttribute",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSecurityGroupRules",
                "ec2:DescribeImages",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeSubnets",
                "ec2:CreateSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateTags",
                "ec2:CreateKeyPair",
                "ec2:DescribeRouteTables",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeNatGateways",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribePrefixLists",
                "ec2:DescribeVpcEndpoints",
                "ec2:DescribeVpcEndpointServices",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:DescribeAddresses",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:GetLaunchTemplateData",
                "ec2:DescribeTags",

            ],
            "Resource": "*"
         },
         {
            "Sid": "GetSTS",
            "Effect": "Allow",
            "Action": [
                "sts:GetServiceBearerToken"
            ],
            "Resource": "*"
         },
        {
            "Sid": "DescribeKMS",
            "Effect": "Allow",
            "Action": [
                "kms:DescribeKey",
                "kms:GetKeyPolicy",
                "kms:ListAliases"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RDSDescribe",
            "Effect": "Allow",
            "Action": [
                "rds:DescribeDBInstances",
                "rds:DescribeDBSubnetGroups",
                "rds:DescribeTags",
            ],
            "Resource": "*"
        },
        {
            "Sid": "GetOpenID",
            "Effect": "Allow",
            "Action": [
                "iam:GetOpenIDConnectProvider",
                "iam:ListOpenIDConnectProviders"
            ],
            "Resource": "*"
        }

    ],
    
  })
}

resource "aws_iam_policy_attachment" "eks_developer_policy_attachment" {
  name = "eks_developer_policy_attachment"
  policy_arn = aws_iam_policy.DeveloperAcccess.arn
  roles      = [aws_iam_role.eks_cluster_developer.name]
}
