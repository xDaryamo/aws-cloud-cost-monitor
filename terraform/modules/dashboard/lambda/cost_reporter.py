import boto3
import json
import os
from datetime import datetime, timedelta

def lambda_handler(event, context):
    ce = boto3.client('ce')
    s3 = boto3.client('s3')
    
    # Define period: last 7 days
    end_date = datetime.now().date()
    start_date = end_date - timedelta(days=7)
    
    # Retrieve costs grouped by service
    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': start_date.strftime('%Y-%m-%d'),
            'End': end_date.strftime('%Y-%m-%d')
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
    )
    
    # Format data for our dashboard
    costs = []
    for group in response['ResultsByTime'][0]['Groups']:
        service_name = group['Keys'][0]
        amount = float(group['Metrics']['UnblendedCost']['Amount'])
        if amount > 0.01: # Exclude services with negligible cost
            costs.append({
                'service': service_name,
                'amount': round(amount, 2)
            })
    
    # Prepare the final JSON
    output = {
        'last_update': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'period': f"{start_date} to {end_date}",
        'costs': costs
    }
    
    # Save to S3
    bucket_name = os.environ['BUCKET_NAME']
    s3.put_object(
        Bucket=bucket_name,
        Key='data.json',
        Body=json.dumps(output),
        ContentType='application/json'
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Dashboard updated successfully!')
    }