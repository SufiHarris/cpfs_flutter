const amplifyconfig = '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify/cli",
                "Version": "0.1.0",
                "IdentityManager": {
                    "Default": {}
                },
                "CredentialsProvider": {
                    "CognitoIdentity": {
                        "Default": {
                            "PoolId": "us-east-1:8357479e-1309-482e-892b-753a0b263cdc",
                            "Region": "us-east-1"
                        }
                    }
                },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "us-east-1_lFxtsd3Mm",
                        "AppClientId": "2hekkrh1er76nb6ivti4qh42bk",
                        "Region": "us-east-1"
                    }
                },
                "Auth": {
                    "Default": {
                        "authenticationFlowType": "USER_SRP_AUTH",
                        "usernameAttributes": ["EMAIL"],
                        "signupAttributes": ["EMAIL"],
                        "passwordProtectionSettings": {
                            "passwordPolicyMinLength": 8,
                            "passwordPolicyCharacters": []
                        },
                        "mfaConfiguration": "OFF",
                        "mfaTypes": ["SMS"],
                        "verificationMechanisms": ["EMAIL"]
                    }
                }
            }
        }
    },
    "api": {
        "plugins": {
            "awsAPIPlugin": {
                "cfsmarketplace": {
                    "endpointType": "GraphQL",
                    "endpoint": "https://4v4auhw7abhf3g4sswybs64plu.appsync-api.us-east-1.amazonaws.com/graphql",
                    "region": "us-east-1",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-li7u4imiz5gzvlrlvufzbpzo24"
                }
            }
        }
    },
    "storage": {
        "plugins": {
            "awsS3StoragePlugin": {
                "bucket": "cfsmarketplace-client-files-1759093765",
                "region": "us-east-1",
                "defaultAccessLevel": "guest"
            }
        }
    }
}''';
