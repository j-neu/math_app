"""
Extract text from all PDF files in a directory.
This script processes all PDFs in PIKAS_Kartei and creates corresponding .txt files.
"""

import sys
from pathlib import Path

try:
    import PyPDF2
except ImportError:
    print("PyPDF2 not found. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "PyPDF2"])
    import PyPDF2


def extract_text_from_pdf(pdf_path, output_path):
    """
    Extract text from a PDF file and save to a text file.

    Args:
        pdf_path: Path to the PDF file
        output_path: Path to save extracted text

    Returns:
        Extracted text as string
    """
    extracted_text = []

    try:
        with open(pdf_path, 'rb') as pdf_file:
            pdf_reader = PyPDF2.PdfReader(pdf_file)
            total_pages = len(pdf_reader.pages)

            for page_num in range(total_pages):
                page = pdf_reader.pages[page_num]
                text = page.extract_text()

                # Add page separator
                extracted_text.append(f"\n{'='*80}\n")
                extracted_text.append(f"PAGE {page_num + 1}\n")
                extracted_text.append(f"{'='*80}\n\n")
                extracted_text.append(text)
                extracted_text.append("\n\n")

            return "".join(extracted_text), total_pages

    except Exception as e:
        print(f"  Error reading PDF: {e}")
        raise


def process_directory(directory_path):
    """
    Process all PDF files in a directory.

    Args:
        directory_path: Path to directory containing PDFs
    """
    directory = Path(directory_path)

    if not directory.exists():
        raise FileNotFoundError(f"Directory not found: {directory}")

    # Find all PDF files
    pdf_files = list(directory.glob("*.pdf"))

    if not pdf_files:
        print(f"No PDF files found in {directory}")
        return

    print(f"Found {len(pdf_files)} PDF file(s) in {directory}")
    print("="*80)

    successful = 0
    failed = 0

    for i, pdf_path in enumerate(pdf_files, 1):
        output_path = pdf_path.with_suffix('.txt')

        print(f"\n[{i}/{len(pdf_files)}] Processing: {pdf_path.name}")

        try:
            text, pages = extract_text_from_pdf(pdf_path, output_path)

            # Save to file
            with open(output_path, 'w', encoding='utf-8') as output_file:
                output_file.write(text)

            print(f"  Success: {pages} pages, {len(text)} characters")
            print(f"  Saved to: {output_path.name}")
            successful += 1

        except Exception as e:
            print(f"  Failed: {e}")
            failed += 1

    print("\n" + "="*80)
    print(f"Summary: {successful} successful, {failed} failed out of {len(pdf_files)} total")


if __name__ == "__main__":
    # Default directory
    default_dir = Path(__file__).parent / "PIKAS_Kartei"

    # Allow custom directory via command line argument
    if len(sys.argv) > 1:
        directory = sys.argv[1]
    else:
        directory = default_dir

    try:
        process_directory(directory)
    except Exception as e:
        print(f"Failed to process directory: {e}")
        sys.exit(1)
