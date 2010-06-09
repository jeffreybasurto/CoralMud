# send an offline message to a certain player.
class Message
  include DataMapper::Resource
  property :id, Serial
  property :from, String
  property :text, Text

  belongs_to :player

  def to_s
    if from
      "###{id}: From: #{Player.get(from).name}" + ENDL + "#{text}" + ENDL
    end
  end
end

