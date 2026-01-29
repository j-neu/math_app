"""
Extract text from PIKAS PDF document.
This script extracts all selectable text from the PDF file.
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


def extract_text_from_pdf(pdf_path, output_path=None):
    """
    Extract text from a PDF file and optionally save to a text file.

    Args:
        pdf_path: Path to the PDF file
        output_path: Optional path to save extracted text (default: same name as PDF with .txt extension)

    Returns:
        Extracted text as string
    """
    pdf_path = Path(pdf_path)

    if not pdf_path.exists():
        raise FileNotFoundError(f"PDF file not found: {pdf_path}")

    # Default output path
    if output_path is None:
        output_path = pdf_path.with_suffix('.txt')
    else:
        output_path = Path(output_path)

    print(f"Extracting text from: {pdf_path}")
    print(f"Output will be saved to: {output_path}")

    extracted_text = []

    try:
        with open(pdf_path, 'rb') as pdf_file:
            pdf_reader = PyPDF2.PdfReader(pdf_file)
            total_pages = len(pdf_reader.pages)

            print(f"Total pages: {total_pages}")

            for page_num in range(total_pages):
                print(f"Processing page {page_num + 1}/{total_pages}...", end='\r')
                page = pdf_reader.pages[page_num]
                text = page.extract_text()

                # Add page separator
                extracted_text.append(f"\n{'='*80}\n")
                extracted_text.append(f"PAGE {page_num + 1}\n")
                extracted_text.append(f"{'='*80}\n\n")
                extracted_text.append(text)
                extracted_text.append("\n\n")

            print(f"\nExtraction complete!")

    except Exception as e:
        print(f"\nError reading PDF: {e}")
        raise

    # Combine all text
    full_text = "".join(extracted_text)

    # Save to file
    try:
        with open(output_path, 'w', encoding='utf-8') as output_file:
            output_file.write(full_text)
        print(f"Text saved to: {output_path}")
        print(f"Total characters extracted: {len(full_text)}")
    except Exception as e:
        print(f"Error saving text file: {e}")
        raise

    return full_text


if __name__ == "__main__":
    # Default PDF path
    default_pdf = Path(__file__).parent / "1_unterricht_mathekartei_onlineversion.pdf"

    # Allow custom path via command line argument
    if len(sys.argv) > 1:
        pdf_path = sys.argv[1]
    else:
        pdf_path = default_pdf

    # Optional output path via second argument
    output_path = sys.argv[2] if len(sys.argv) > 2 else None

    try:
        extract_text_from_pdf(pdf_path, output_path)
    except Exception as e:
        print(f"Failed to extract text: {e}")
        sys.exit(1)
