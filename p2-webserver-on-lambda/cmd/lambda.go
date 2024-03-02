package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

func main() {
	// Register the lambbda, this is where you'll want to load in
	// - Secrets
	// - Large files
	// - Perform bootstrap processes
	lambda.Start(handler)
}

var (
	TableName = aws.String("simple_webserver_storage")
)

// Representation of our dyanmo object as a struct that can be marshalled
type IPAccessItem struct {
	IPAddress   string `json:"IPAddress" dynamodbav:"IPAddress"`
	VisitCount  int    `json:"VisitCount" dynamodbav:"VisitCount"`
	LastVisited string `json:"LastVisited" dynamodbav:"LastVisited"`
}

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	//  Snag IP Address from the headers of the request
	fmt.Printf("Processing request data for request %s.\n", request.RequestContext.RequestID)
	fmt.Println("Headers:", request.Headers)
	ip_address := request.Headers["x-forwarded-for"]

	var item IPAccessItem

	// Load AWS config (lambda provides secrets out of box)
	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithRegion("us-west-2"), // Replace with your AWS region
	)
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}
	// Create a dynamodb client
	dynamodbClient := dynamodb.NewFromConfig(cfg)

	// Search for an item given the IP Address
	// This block just defines the query
	query := &dynamodb.GetItemInput{
		TableName: TableName,
		Key: map[string]types.AttributeValue{
			"IPAddress": &types.AttributeValueMemberS{Value: ip_address},
		},
	}

	// Run the query defined above and handle errors
	result, err := dynamodbClient.GetItem(ctx, query)
	if err != nil {
		log.Fatalf("failed to get item, %v", err)
	}

	if result.Item == nil {
		// No item found in database, so make a new one
		fmt.Println("No item found with the specified ID")
		item = IPAccessItem{
			IPAddress:   ip_address,
			VisitCount:  1,
			LastVisited: time.Now().String(),
		}
	} else {
		// Unmarshall item from dynamo and modify
		err = attributevalue.UnmarshalMap(result.Item, &item)
		if err != nil {
			log.Fatalf("failed to unmarshal result item, %v", err)
		}

		item.VisitCount += 1
		item.LastVisited = time.Now().String()
	}

	// Store back in dynamodb
	av, err := attributevalue.MarshalMap(item)
	if err != nil {
		log.Fatalf("failed to marshal item, %v", err)
	}
	input := &dynamodb.PutItemInput{
		Item:      av,
		TableName: TableName,
	}

	// Store item in dyanmodb
	_, err = dynamodbClient.PutItem(ctx, input)
	if err != nil {
		log.Fatalf("failed to put item in table, %v", err)
	}

	fmt.Printf("Successfully added '%s' to table\n", item.IPAddress)

	// Decode for response
	output, _ := json.Marshal(item)
	return events.APIGatewayProxyResponse{Body: string(output), StatusCode: 200}, nil
}
