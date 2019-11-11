require 'pdf_forms'
require 'base64'
require_relative 'signature_pdf'


class ReportFiller
  attr_accessor :params, :path

  def self.fill(params)
    i = self.new
    i.params = params
    i.fill
  end

  def fill
    Dir.mktmpdir do |dir|
      self.path = Pathname.new(dir)
      fill_form
      add_signatures
      encode
    end
  end

  # required_params( 
  #   :company_address, 
  #   :drivers_name, 
  #   :date, 
  #   :vehicle_number, 
  #   :vehicle_make_color,
  #   :ahcccs_id,
  #   :ahcccs_id_2,
  #   :dob,
  #   :dob_2,
  #   :member_name,
  #   :member_name_2,
  #   :mailing_address,
  #   :pickup_address_1,
  #   :pickup_time_1,
  #   :pickup_odometer_1,
  #   :dropoff_address_1,
  #   :dropoff_time_1,
  #   :dropoff_odometer_1,
  #   :reason_for_visit_1,
  #   :signature,
  #   :driver_signature,
  #   :signature_date)

  private

  # PDFtk doesn't know how to deal with images so we're creating a PDF with Prawn
  # that contains the signatures and then merging the two together
  # 
  def add_signatures
    SignaturePdf.make(params, path)
    pdftk.multistamp(flattened_path, signatures_path, final_path)
  end

  # The response should be a json object with the PDF base64 encoded
  # Or an error if there was a problem
  # 
  def encode
    file = Base64.encode64(File.open(final_path, "rb").read)
    {pdf: file}
  end

  # Use PDFtk to fill in the form fields and remove the form from the PDF
  # 
  def fill_form
    pdftk.fill_form('./assets/form_template.pdf', flattened_path, self.params, :flatten => true)
  end

  def pdftk
    @pdftk ||= PdfForms.new('/usr/bin/pdftk')
  end

  def flattened_path
    path.join('flattened_form.pdf')
  end

  def signatures_path
    path.join('signatures.pdf')
  end

  def final_path
    path.join('final.pdf')
  end

end