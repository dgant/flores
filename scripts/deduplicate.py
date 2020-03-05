import argparse
import typing
from io import TextIOWrapper

def deduplicate_streams(input_src: TextIOWrapper, input_tgt: TextIOWrapper, output_src: TextIOWrapper, output_tgt: TextIOWrapper) -> None:
  """
  Deduplicates a parallel corpus.
  """
  # Hashes of matched strings
  matched_strings = set()
  
  # Step through both corpora
  # If neither line matches one we've seen before,
  # write it to the depduplicated corpora
  for line_src, line_tgt in zip(input_src, input_tgt):
    line_src = line_src.rstrip('\n')
    line_tgt = line_tgt.rstrip('\n')
    hash_src = hash(line_src)
    hash_tgt = hash(line_tgt)
    matched_src = hash_src in matched_strings
    matched_tgt = hash_tgt in matched_strings
    if not matched_src:
      matched_strings.add(hash_src)
    if not matched_tgt:
      matched_strings.add(hash_tgt)
    if not matched_src and not matched_tgt:
      print(line_src, file=output_src)
      print(line_tgt, file=output_tgt)

def deduplicate(input_src: str, input_tgt: str, output_src: str, output_tgt: str) -> None:
  """
  Deduplicates a parallel corpus.
  """
  input_src_file = open(input_src, 'r')
  input_tgt_file = open(input_tgt, 'r')
  output_src_file = open(output_src, 'w')
  output_tgt_file = open(output_tgt, 'w')  
  deduplicate_streams(input_src_file, input_tgt=input_tgt_file, output_src=output_src_file, output_tgt=output_tgt_file)

def validate_alignment(input_src: str, input_tgt: str, output_src: str, output_tgt: str) -> bool:
  pass
  
def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--input-src', required=True, help='Path to source language input file')
  parser.add_argument('--input-tgt', required=True, help='Path to target language input file')
  parser.add_argument('--output-src', required=True, help='Path to source language output file')
  parser.add_argument('--output-tgt', required=True, help='Path to target language output file')
  parser.add_argument('--validate-alignment', action='store_true', help='Spot-check alignment of parallel corpora after processing')
  args = parser.parse_args()
  deduplicate(args.input_src, args.input_tgt, args.output_src, args.output_tgt)
  if (args.validate_alignment):
    validate_alignment(args.input_src, args.input_tgt, args.output_src, args.output_tgt)

if __name__ == '__main__':
  main()
