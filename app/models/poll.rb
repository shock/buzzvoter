require 'ruby-debug'
class Poll < ActiveRecord::Base
  named_scope :recent, lambda { |limit| 
    limit ||= 5
      {:conditions => "", :limit=>limit, :order=>"created_at DESC"} 
  }
  
  validates_presence_of :answers, :url
  validates_uniqueness_of :url
  
  private

  class AnswerValidationError < RuntimeError; end
  
  def self.get_answers_from_form_fields answers, abbrs
    puts "answers: #{answers.inspect}"
    puts "abbrs: #{abbrs.inspect}"
    answer_column = ""
    answers.each do |answer|
      abbr = abbrs.shift
      if answer.blank? || abbr.blank?
        raise AnswerValidationError.new( "Answer and Abbreviation fields cannot be blank." );
      elsif !(abbr =~ /^\w*$/)
        raise AnswerValidationError.new( "Abbreviation fields must contain alpha-numeric characters only with no spaces." );
      elsif answer =~ /\|/ || abbr =~ /\|/
        raise AnswerValidationError.new( "Answers cannot contain the '|' character." );
      else
        answer_column += "#{answer}|#{abbr}\n"
      end
    end
    answer_column
  end
  
  public
  
  def self.create_unique_url
    url = Time.now.utc.strftime("%y%j%H%M%S")
  end
  
  # creates a new poll from the supplied form fields
  def self.new_from_form_fields params
    answer = params.delete(:answer)
    abbr = params.delete(:abbr)
    poll = Poll.new( params )
    begin
      poll.answers = get_answers_from_form_fields( answer, abbr )
    rescue AnswerValidationError
      poll.errors.add( :answer, $!.to_s )
    end
    poll
  end

  # updates a poll from the supplied form fields
  def update_from_form_fields params
    answer = params.delete(:answer)
    abbr = params.delete(:abbr)
    begin
      params[:answers] = Poll.get_answers_from_form_fields( answer, abbr )
    rescue AnswerValidationError
      return false
    end
    update_attributes(params)
  end
  
  def answers_as_array
    answer_array = []
    answers.split("\n").each do |answer_row|
      answer_array << answer_row.split("|")
    end
    answer_array
  end
  
  def self.find_by_id_or_url id_or_url
    begin
      poll = Poll.find(id_or_url)
    rescue ActiveRecord::RecordNotFound
      poll = Poll.find_by_url(id_or_url)
    end
  end
end
