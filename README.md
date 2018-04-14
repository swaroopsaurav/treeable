# Treeable

Any model which has belongs_to and has_many relation with itself can use this. It exposes a lot of ready to use methods.

## Installation

```
gem install treeable	
```
Once the gem is installed you can include the module for any model. You will need to specify the column which holds the parent id (default: `parent_id`) and a column where Treeable will store the path (default: `path`). 
```
class User < ApplicationRecord

	include Treeable
    
    treeable_path_column :path
    treeable_parent_column :parent_id
end
```

## Class Methods
* `roots`: Get all the root elements of this class
* `json_tree(nodes)`: Prints all the nodes and their children.
	```ruby
    p User.json_tree(User.all)
    # = > [{:id=>1, :children=>[{:id=>6, :children=>[{:id=>7, :children=>[]}]}]}, {:id=>2, :children=>[{:id=>5, :children=>[]}]}, {:id=>3, :children=>[]}, {:id=>4, :children=>[]}, {:id=>5, :children=>[]}, {:id=>6, :children=>[{:id=>7, :children=>[]}]}, {:id=>7, :children=>[]}] 
    ```
 * `leaves`: Get all leaf nodes


## Associations
Treeable automatically defines two associations:
* `parent`: `belongs_to` relation to same class and return the parent node
* `children`: ``has_many`` relation and returns all the immediate children
## Instance Methods
* `parent_map`: Map over all the parent nodes and executes the block provided
  ```ruby	
      User.last.parent_map{|k| p k.id}
  ```
* `children_map`: Map over all the children node and executes the block provided 
  ```ruby	
      User.last.children_map{|k| p k.id}
  ```
* `leaf_nodes`: Returns all the leafs from this node
* `nodes_from_root`: Returns all the ancestors of the node
* `	is_leaf`: Returns wheather the node is leaf or not
* `is_root`: Returns if the node is root or noe
* `all_children`: Returns the list of all the children of the node
* `root`: Find the root parent node

## Authors

* **Saurav Swaroop**