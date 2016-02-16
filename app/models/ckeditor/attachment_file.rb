# TODO - remove this. I don't think we use it anymore. (But check the CMS—you should be able to add an image in the WYSIWYG editor.)
class Ckeditor::AttachmentFile < Ckeditor::Asset
  has_attached_file :data,
                    url: "/ckeditor_assets/attachments/:id/:filename",
                    path: ":rails_root/public/ckeditor_assets/attachments/:id/:filename"

  validates_attachment_content_type :data,
    content_type: ['image/pjpeg','image/jpeg','image/png','image/gif', 'image/x-png']
  validates_attachment_size :data, less_than: 100.megabytes
  validates_attachment_presence :data

	def url_thumb
	  @url_thumb ||= Ckeditor::Utils.filethumb(filename)
	end
end
