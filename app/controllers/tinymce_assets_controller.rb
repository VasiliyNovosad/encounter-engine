class TinymceAssetsController < ApplicationController
  respond_to :json

  def create
    # geometry = Paperclip::Geometry.from_file params[:file]
    # image    = Image.create(image: params.permit(:file)[:file])# params.permit(:file))
    #
    # render json: {
    #   image: {
    #     url:    image.image_url,
    #     height: geometry.height.to_i,
    #     width:  geometry.width.to_i
    #   }
    # }, layout: false, content_type: 'text/html'
    upload = Cloudinary::Uploader.upload(params['file'])
    render json: { image: { url: upload['url'] } }, content_type: 'text/html'
  end
end
