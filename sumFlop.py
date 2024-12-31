import csv

# Define the path to your input and output files
input_file_path = "flopRes.txt"
output_file_path = "flopRes.csv"

# Step 1: Read the text file, skip the first 7 rows, and save the remaining content to a new CSV file
with open(input_file_path, "r") as infile:
    lines = infile.readlines()  # Read all lines

# Skip the first 7 lines and write the remaining lines to a new CSV file
with open(output_file_path, "w", newline='') as outfile:
        outfile.writelines(lines[7:])

# Step 2: Process the newly created CSV file to sum the "Metric Value" column
total_sum = 0

with open(output_file_path, newline='') as csvfile:
    reader = csv.DictReader(csvfile)  # Read the CSV file

    # Iterate through the rows and sum the Metric Values
    for row in reader:
        # Extract the Metric Value and convert it to an integer
        metric_value = int(row["Metric Value"])
        total_sum += metric_value  # Add to the total sum

# Output the total sum
print(f"The sum of all Metric Values (after skipping the first 7 lines) is: {total_sum}")
