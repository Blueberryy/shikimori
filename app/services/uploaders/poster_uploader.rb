class Uploaders::PosterUploader < Shrine
  # include ImageProcessing::MiniMagick

  # plugin :processing
  # plugin :versions
  # plugin :delete_raw
  # plugin :validation_helpers
  # plugin :determine_mime_type
  # plugin :presign_endpoint
  # plugin :delete_promoted
  #
  # plugin :default_url_options, store: ->(io, **_options) do
  #   {
  #     response_content_disposition: ContentDisposition.format(
  #       disposition: 'inline',
  #       filename: io.original_filename
  #     )
  #   }
  # end
  #
  # Attacher.validate do
  #   validate_max_size(
  #     15.megabytes,
  #     message: 'is too large (max is 15 MB)'
  #   )
  #   validate_mime_type_inclusion(
  #     %w[image/jpg image/jpeg image/png],
  #     message: 'must be JPEG or PNG'
  #   )
  # end
  #
  # process(:store) do |io, _context|
  #   original = io.download
  #
  #   pipeline = ImageProcessing::MiniMagick
  #     .source(original)
  #     .sampling_factor('4:2:0')
  #     .strip
  #     .quality(85)
  #     .interlace('JPEG')
  #
  #   size_256 = pipeline.resize_to_fill!(256, 364)
  #   size_444 = pipeline.resize_to_fill!(444, 508)
  #   size_1200 = pipeline.resize_to_limit(1200, nil).convert!('jpg')
  #
  #   original.close
  #
  #   {
  #     original: size_1200,
  #     x256: size_256,
  #     x444: size_444
  #   }
  # end
  #
  # def generate_location(io, context)
  #   box_image = context[:record]
  #   ['box_images', box_image.box_id.to_s, super].compact.join('/')
  # end
end
