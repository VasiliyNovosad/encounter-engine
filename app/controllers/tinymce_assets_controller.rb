class TinymceAssetsController < ApplicationController
  protect_from_forgery with: :null_session
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
    if params['file'].content_type == 'video/mp4' || params['file'].content_type == 'video/avi'
      upload = Cloudinary::Uploader.upload(params['file'], resource_type: :video)
    else
      upload = Cloudinary::Uploader.upload(params['file'])
    end
    # render json: { file: { url: upload['secure_url'] }, content_type: params['file'].content_type }, content_type: 'text/html'
    render json: { location: upload['secure_url'] }
  end
end
