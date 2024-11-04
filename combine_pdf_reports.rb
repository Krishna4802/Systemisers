require 'combine_pdf'

module ProjectReport
  class CombinePdfReports
    def initialize(pdf_paths)
      @pdf_paths = pdf_paths
    end

    def combine_and_generate(output_path)
      combined_pdf = CombinePDF.new

      @pdf_paths.each do |pdf_path|
        combined_pdf << CombinePDF.load(pdf_path)
      end

      combined_pdf.save(output_path)
    end
  end
end
