import boto3
import itertools
from pyspark.sql import SparkSession, Row
from math import ceil

# def _parse_arguments():
#     """ Parse arguments provided by spark-submit commend"""
#     parser = argparse.ArgumentParser()
#     parser.add_argument("--job", required=True)
#     return parser.parse_args()

# def move_file_to_glacier(list_of_rows):
#   sess = boto3.session.Session(region_name='us-east-1')
#   s3res = sess.resource('s3')

#   for row in list_of_rows:
#     copy_source = {
#       'Bucket': row[0],
#       'Key': row[1]
#     }

#     s3res.meta.client.copy(
#       CopySource=copy_source,
#       Bucket='my-destination-bucket',
#       Key=row[1],
#       ExtraArgs={'StorageClass': 'GLACIER'}
#     )

#     yield Row(
#       bucket=row[0],
#       key=row[1],
#       file_number=row[2],
#       total_files=row[3]
#     )

def count_buckets(li_rows):
    sess = boto3.session.Session(region_name='us-east-1', 
        aws_access_key_id='',
        aws_secret_access_key=''
    )
    copy_source = {
      'Bucket': 'sample-bucket-21341921441210',
      'Key': 'bsdk/2022-06-1000:15:35.504101.parquet'
    }
    s3res = sess.resource('s3')
    for row in li_rows:
        s3res.meta.client.copy(
            CopySource=copy_source,
            Bucket=row[0],
            Key=row[1],
        )
        yield Row(bucket=row[0],key=row[1])

def main():
    """ Main function excecuted by spark-submit command"""
    # args = _parse_arguments()

    # # with open("/opt/spark/app/config.json", "r") as config_file:
    # #     config = json.load(config_file)

    spark = SparkSession\
        .builder\
        .appName("app_name")\
        .getOrCreate()
    num_ops = 10**5
    # List of files we want to perform operations on
    rows = list(itertools.chain(*[[('sample-bucket-21341921441210', f"test_unpartitioned_data/part_str={j}/file-{i}.parquet") for i in range(num_ops) for j in range(16)]]))
    
    sc = spark._sc
    # Number of concurrent operations allowed
    files = sc.parallelize(rows).repartition(ceil(num_ops/3450))
    print(files.getNumPartitions())
    output = files.mapPartitions(count_buckets)
    print(output.count())
    # print(f"Count: {output.count()} :: Total: {output.select('total_files').limit(1).collect()[0].total_files}")
    # output.unpersist()


if __name__ == "__main__":
    main()
