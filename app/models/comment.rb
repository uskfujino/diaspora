class Comment
  include MongoMapper::Document
  include ROXML
  include Diaspora::Webhooks
  include Encryptable
  include Diaspora::Socketable
  
  xml_accessor :text
  xml_accessor :person, :as => Person
  xml_accessor :post_id
  xml_accessor :_id 
  
  key :text, String
  timestamps!
  
  key :post_id, ObjectId
  belongs_to :post, :class_name => "Post"
  
  key :person_id, ObjectId
  belongs_to :person, :class_name => "Person"

  validates_presence_of :text
  
  def push_upstream
    Rails.logger.info("GOIN UPSTREAM")
    push_to([post.person])
  end

  def push_downstream
    Rails.logger.info("SWIMMIN DOWNSTREAM")
    push_to(post.people_with_permissions)
  end

  #ENCRYPTION
  
  before_validation :sign_if_mine, :sign_if_my_post
  validates_true_for :post_creator_signature, :logic => lambda {self.verify_post_creator_signature}
  
  xml_accessor :creator_signature
  xml_accessor :post_creator_signature
  
  key :creator_signature, String
  key :post_creator_signature, String

  def signable_accessors
    accessors = self.class.roxml_attrs.collect{|definition| 
      definition.accessor}
    accessors.delete 'person'
    accessors.delete 'creator_signature'
    accessors.delete 'post_creator_signature'
    accessors
  end

  def signable_string
    signable_accessors.collect{|accessor| 
      (self.send accessor.to_sym).to_s}.join ';'
  end

  def verify_post_creator_signature
    if person.owner.nil?
      verify_signature(post_creator_signature, post.person)
    else
      true
    end
  end
  
  
  protected
   def sign_if_my_post
    unless self.post.person.owner.nil?
      self.post_creator_signature = sign_with_key self.post.person.encryption_key
    end
  end 

end
