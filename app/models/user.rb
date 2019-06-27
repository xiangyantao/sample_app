class User < ApplicationRecord

    attr_accessor :remember_token, :activation_token

    before_save   :downcase_email
    before_create :create_activation_digest

    validates :name, presence: true, length: {maximum: 50}
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    validates :email, presence: true, 
                      length: {maximum: 255}, 
                      format: { with: VALID_EMAIL_REGEX },
                      uniqueness: { case_sensitive: false }
    # 新建用户、修改用户时检查密码不能为空格，不能小于6个字符，若更新用户密码时，可跳过验证
    validates :password, presence: true,length: { minimum: 6 }, allow_nil:true
    # 仅在新建用户时，检查password和password_confirmation的存在性（不为nil）和匹配性
    has_secure_password

    class << self
      # 返回指定字符串的哈希摘要
      def digest(string)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                      BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
      end

      # 返回一个随机令牌
      def new_token
        SecureRandom.urlsafe_base64
      end
    end

    # 为了持久保存会话，在数据库中记住用户
    def remember
      self.remember_token = User.new_token
      update_attribute(:remember_digest, User.digest(remember_token))
    end

    # 如果指定的令牌和摘要匹配，返回 true
    def authenticated?(attribute, token)
      digest = self.send("#{attribute}_digest")
      return false if digest.nil?
      BCrypt::Password.new(digest).is_password?(token)
    end

    # 忘记用户
    def forget
      update_attribute(:remember_digest, nil)
    end

    # 激活账户
    def activate
      update_attribute(:activated,    true)
      update_attribute(:activated_at, Time.zone.now)
    end

  # 发送激活邮件
    def send_activation_email
      UserMailer.account_activation(self).deliver_now
    end


    private
      #把电子邮件地址转换成小写
      def downcase_email
        self.email = email.downcase
      end

      #创建并赋值激活令牌和摘要
      def create_activation_digest
        self.activation_token  = User.new_token
        self.activation_digest = User.digest(activation_token)
      end

end
