variable "resource_id" {
}

variable "api_id" {
}

variable "response_methods" {
  default = []
}

variable "allowed_origin" {
}

resource "aws_api_gateway_method_response" "cors_method_response_200" {
  for_each = toset(var.response_methods)

  rest_api_id   = var.api_id
  resource_id   = var.resource_id
  http_method   = each.key

  status_code   = 200

  response_parameters = {
      "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method" "options_method" {
    rest_api_id   = var.api_id
    resource_id   = var.resource_id
    http_method   = "OPTIONS"
    authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
    rest_api_id   = var.api_id
    resource_id   = var.resource_id
    http_method   = aws_api_gateway_method.options_method.http_method
    status_code   = 200

    response_models = {
        "application/json" = "Empty"
    }

    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }

    depends_on = [aws_api_gateway_method.options_method]
}

resource "aws_api_gateway_integration" "options_integration" {
    rest_api_id   = var.api_id
    resource_id   = var.resource_id
    http_method   = aws_api_gateway_method.options_method.http_method
    type          = "MOCK"
    depends_on = [aws_api_gateway_method.options_method]

    request_templates = {
        "application/json" = jsonencode(
            {
                statusCode = 200
            }
        )
    }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = var.api_id
    resource_id   = var.resource_id
    http_method   = aws_api_gateway_method.options_method.http_method
    status_code   = aws_api_gateway_method_response.options_200.status_code

    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
        "method.response.header.Access-Control-Allow-Origin" = var.allowed_origin
    }

    depends_on = [aws_api_gateway_method_response.options_200]
}