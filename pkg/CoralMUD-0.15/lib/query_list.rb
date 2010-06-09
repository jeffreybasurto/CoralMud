class Functor
  attr_reader :val, :fun
  def self.map_to_function filter, options_hash={}
    cases = [[/^\/([0-9a-zA-Z@_.-?(){}*]+)\/$/, :regexp],
             [/^#(\d+)$/, :idn],
             [/^x(\d+)$/, :times],
             [/^(\d+)$/,:specific],
             [/^all$/, :all],
             [/^(\d+)-(\d+)$/, :range],
             [/^~(\d+)$/,:alternate],
             [/^(.*)$/, :match]]
    m, sym= nil, nil
    cases.each do |ec|
      next if options_hash[:exceptions] && options_hash[:exceptions].include?(ec[1])
      m, sym = filter.match(ec[0]), ec[1]
      break if m
    end

    return Functor.new(sym, m ? m.captures : nil, options_hash)
  end


  # these don't require :specific being attached the front.  I.e. they let you return multiple items.
  def self.specific_exceptions
    [:alternate, :times, :all, :range, :specific]
  end

  # defaults are set up for Items
  def initialize type, val, options={}
    @options = {:name=>:name, :id=>:id}.merge(options)
    @val = val
    @fun = type
  end
  # call this functor with an array to query. 
  def call data_set
    @fun ? self.send(@fun, data_set) : []
  end 

  private
  def range data_set
    data_set[(@val[0].to_i-1..@val[1].to_i-1)] || []
  end
  def match data_set
    data_set.select do |obj| 
      against = obj.send(@options[:name]).multi_args
      found = false
      against.each do |keyword|
        found = true if keyword.downcase.start_with?(@val[0].downcase)
      end
      found
    end
  end
  def idn data_set
    data_set.select { |obj| obj.send(@options[:id]).to_s == @val[0]}
  end 
  def specific data_set
    [data_set[@val[0].to_i-1] || []].flatten
  end
  def times data_set
    data_set[0..@val[0].to_i-1] || []
  end
  def alternate data_set
    i = 0
    data_set.select { |obj| 
      i += 1
      i % @val[0].to_i == 0
    }
  end
  def regexp data_set
    begin 
      exp = Regexp.new(@val[0])
      data_set.select{ |obj| obj.send(@options[:name]).match(exp) }
    rescue
      []
    end
  end
  def all data_set
    data_set
  end
end


# the concept is we parse what we want from the string passed.
# We return back the items found from a given list.
def query_parse str, main_list, destroy=false, options={}
  valid_commands = ["and", "or", "from"]

  # generates an array of possible commands.
  commands = str.squeeze(" ").multi_args
  return [] if commands.empty? || commands[0].empty?

  # Always starts with "and" command
  full_object_query = ["and", commands.shift]

  # collects one and only one query phrase.
  loop do
    break if !commands[0] || commands[0].empty? || !valid_commands.include?(commands[0])

    # if it's from, link it with the previous object.
    if commands[0] == "from"
      break if !full_object_query[-1]
      full_object_query[-1] = "#{full_object_query[-1]} #{commands.shift} #{commands.shift}"
    else
      (full_object_query << commands.shift(2)).flatten!
    end
  end

  # destroys what we got from the original string if destroy set to true.
  if destroy
    full_object_query.each do |each_query|
      str.sub!(each_query.to_s, "")
    end
    str.strip! 
 end

  found_so_far = []
  loop do
    query_comm = full_object_query.shift(2)
    break if !query_comm[0] || !query_comm[1]

    case query_comm[0]
      when "and" then found_so_far.concat(query_list(query_comm[1], main_list, options)) # query the objects in the room with the arg
      when "or" then found_so_far.concat(query_list(query_comm[1], main_list, options)) if found_so_far.empty?
    end
  end
  found_so_far.uniq!
  return found_so_far
end



# query a list (designed for objects)
# example:   query_list "2.sword", inventory_of_items
# list is a hash of identifiers and valid lists.
def query_list str, list, options_hash = {}
  found = [] # returned at the end with a grand list of the items found.

  # first split by space.
  from_list = str.split ' from '
  from_list.reverse!


  next_iteration_list = []
  if list.is_a? Array
    next_iteration_list = list
  elsif list.is_a? Hash
    if from_list.count > 1
      which_keys = query_list(from_list[0], list.keys, {:name=>:to_s, :id=>:__id__, :exceptions=>[:all, :specific, :alternative, :regexp, :times, :idn]}) 
    else
      which_keys = []
    end
    if which_keys.empty?
      list.each_pair do |p|
        next_iteration_list.concat p[1]
      end
    else
      which_keys.each do |key|
        next_iteration_list.concat list[key]
      end
      from_list.shift
    end
  end

  # for each_query in list we need to execute a query on it and hand off the resultant to the next query.
  from_list.each do |each_query|
    s = each_query.split '.'
    funs = []
    s.each do |filter|
      funs.unshift Functor.map_to_function(filter, options_hash)
    end

    funs.push Functor.new(:specific, 1, options_hash) if !Functor.specific_exceptions.include? funs[-1].fun
    
    funs.each do |functor|
      next_iteration_list = functor.call next_iteration_list
    end
    found = next_iteration_list
    next_iteration_list = []
    found.each do |each_found|
      next_iteration_list.concat(each_found.stuff) if each_found.respond_to? :stuff
    end
  end
  
  return found
end

