module Treeable
  extend ::ActiveSupport::Concern

  included do 

    after_create :update_path
    after_update :repopulate_path
    belongs_to :parent, :class_name => self.to_s, :foreign_key => :parent_id 
    has_many :children, :class_name => self.to_s, :foreign_key=> :parent_id

    @treeable_parent = :parent_id
    @treeable_path = :path

    def self.define_association
      belongs_to :parent, :class_name => self.to_s, :foreign_key => @treeable_parent 
      has_many :children, :class_name => self.to_s, :foreign_key=> @treeable_parent 
    end

    def self.treeable_path_column(column_name=nil)
      if column_name
        @treeable_path = column_name.to_sym
      end
      return @treeable_path
    end


    def self.treeable_parent_column(column_name=nil)
      if column_name
        @treeable_parent = column_name.to_sym
        self.define_association
      end
      return @treeable_parent
    end

    def self.json_tree(nodes)
      nodes.map do |node|
        {:id => node.id, :children => json_tree(node.children)}
      end
    end 

    def self.roots
      where(@treeable_parent => nil)
    end  

    def self.leaves
      array = []      
      roots.each do |k|
        array += k.leafs
      end  
      self.where(id: (array.uniq.compact))
    end    
  end  

  def path
    if !self.attributes.keys.include?("path") && self.class.treeable_path_column !="path"
      send(self.class.treeable_path_column)
    end
  end  
      
  def is_leaf
    self.children.empty? 
  end

  def is_root
    self.parent.blank?
  end

  def parent_map(&block)
    (nodes_from_root || []).each{|k| block.call k}
  end 
  
  def children_map(&block)
    unless all_children.empty?
      children.each{|k| k.children_map(&block)}
    end  
  end 

  def leafs
    array = []
    if self.is_leaf
      array << self.id
    else 
      parent_ids = self.all_children.where(self.class.treeable_parent_column => (all_children_ids << self.id)).pluck(self.class.treeable_parent_column)
      array += self.all_children_ids - parent_ids
    end
    array
  end

  def leaf_nodes
    internal_nodes  = self.class.where(self.class.treeable_parent_column => self.all_children_ids).select(self.class.treeable_parent_column).group(self.class.treeable_parent_column).pluck(self.class.treeable_parent_column)
    self.all_children.map{|t| t unless internal_nodes.include?(t[:id])}.uniq.compact
  end  

  def node_ids_from_root
    self.path.split(".").map{|k| k.to_i}
  end

  def nodes_from_root
    self.class.where(:id => node_ids_from_root).order("length(#{self.class.treeable_path_column.to_s}) ASC")
  end  

  def all_children
    self.class.where("#{self.class.treeable_path_column} LIKE '#{self.path}%'").where.not(:id => self.id)
  end  

  def all_children_ids
      all_children.pluck(:id)
  end  

  def repopulate_path
    if self.parent_id_changed?
      child_nodes = all_children
      path = parent ? "#{parent.path}#{self.id}." : "#{self.id}." 
      self.update_column(self.class.treeable_path_column.to_s, path)
      child_nodes.each{|k| k.update_path}
    end
  end 

  def update_path
    new_path = self.parent ? "#{self.parent.path}#{self.id}." : "#{self.id}." 
    self.update_column(self.class.treeable_path_column.to_s, new_path)
  end  

  def root
    self.path.split('.').first.to_i
  end
end