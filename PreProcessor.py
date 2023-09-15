import argparse
import fuzzy
import re


def process_field(field):
    # Convert to uppercase
    field = field.upper()

    # Remove non-alphabetic characters
    field = re.sub(r'[^A-Za-z]', '', field)

    # Remove non-standard characters (e.g., remove all characters except alphanumeric and underscore)
    field = re.sub(r'[^A-Za-z0-9_]', '', field)

    # Left-trim and right-trim
    field = field.strip()

    return field


def transform_records(records, transform_positions):
    transformed_records = []
    for record in records:
        fields = record.split("|")
        transformed_fields = []
        for i, field in enumerate(fields):
            if i in transform_positions:
                transformed_fields.append(process_field(fuzzy.nysiis(field)))
        transformed_records.append(fields + transformed_fields)
    return transformed_records


def transform_records_optimized(record, transform_positions):

    fields = record.split("|")
    transformed_fields = []
    for i, field in enumerate(fields):
        if i in transform_positions:
            transformed_fields.append(process_field(fuzzy.nysiis(field)))
    return (fields + transformed_fields)


def process_files(input_file, output_file, transform_positions):
    with open(input_file, "r") as file:
        input_records = file.read().splitlines()

    trans_records = transform_records(input_records, transform_positions)

    with open(output_file, "w") as file:
        for record in trans_records:
            file.write("|".join(record) + "\n")

    print("Transformation complete. Output written to", output_file)


def process_files_opimized(input_file, output_file, transform_positions):
    with open(input_file, "r") as file:
        with open(output_file, "w") as outfile:
            for line in file:
                line = line.strip()
                trans_record = transform_records_optimized(
                    line, transform_positions)
                outfile.write("|".join(trans_record) + "\n")

    print("Transformation complete. Output written to", output_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="NYSIIS Batch Processing")
    parser.add_argument("input_file", help="Input file name")
    parser.add_argument("output_file", help="Output file name")
    parser.add_argument(
        "-t",
        "--transform-positions",
        nargs="+",
        type=int,
        help="Positions of fields to transform (space-separated)",
    )
    args = parser.parse_args()
    process_files_opimized(
        args.input_file, args.output_file, args.transform_positions)
