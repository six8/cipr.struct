===========
Cipr Struct
===========

Data structures utilities for Corona

Includes:

* cipr.struct.grid.Grid - An efficient 2D grid
* cipr.struct.grid.GridView - Translates a Grid into display coordinates
* cipr.struct.Set - An unorderd set
* cipr.struct.Vector2D - 2D vector operations

Installation
============

Installation is done with `cipr <http://github.com/six8/corona-cipr>`_

::

    cipr install git://github.com/six8/cipr.struct.git

Usage
=====

Some examples. See source for full functionality.

Set::

    local cipr = require 'cipr'
    local Set = cipr.import 'cipr.struct.Set'
   
    local fruit = Set:new({})
    fruit:add('orange')
    fruit:add('pear')
    fruit:add('apple')

    assert(fruit:contains('apple'))

    local cart = Set:new({'apple', 'plum', 'grape'})

    assert(cart:union(fruit):size() == 5)
    assert(cart:intersection(fruit):size() == 1)

Vector2D::

    local cipr = require 'cipr'
    local Vector2D = cipr.import 'cipr.struct.Vector2D'

    local vec1 = Vector2D:new(10, 10)
    local vec2 = Vector2D:new(10, 10)

    assert(vec1:equals(vec2))


    -- Distance
    assert(vec1:dist(vec2) == 0)

    -- Angle
    assert(vec1:angle({x = 0, y = 0}) == -45)