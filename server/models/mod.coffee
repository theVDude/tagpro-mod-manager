mongoose = require "mongoose"
Canvas = require "canvas"
{Image} = require "canvas"

Schema = mongoose.Schema

modSchema = new Schema
  name:
    type: String
    unique: true
    dropDups: true
    required: true
  author:
    type: String
    required: true
  files:
    tiles:
      type: String
      required: true
      dropDups: true
    speedpad: String
    speedpadred: String
    speedpadblue: String
    splats: String
    flair: String
    portal: String
  accepted:
    type: Boolean
    default: false

thumbnailCache = {}

modSchema.methods.getThumbnail = (callback) ->
  if thumbnailCache[@_id]?
    callback thumbnailCache[@_id]
  else
    initMod = @

    canvas = new Canvas(140, 100)
    ctx = canvas.getContext("2d")

    ctx.drawSprite = (img, sx, sy, dx, dy) ->
      this.drawImage img, sx*40, sy*40, 40, 40, dx*40, dy*40, 40, 40

    @model("Mod").findById @_id, "files", (err, objfiles) ->
      if err then console.err err
      if err then throw new Error "Couldn't load file for thumbnail"
      
      # Load image
      tiles = new Image()
      tiles.src = objfiles.files.tiles

      # Draw Tiles
      ctx.drawSprite tiles, 13, 4, -0.5, 0
      ctx.drawSprite tiles, 13, 4, 0.5, 0
      ctx.drawSprite tiles, 13, 4, 1.5, 0

      ctx.drawSprite tiles, 13, 4, -0.5, 1
      ctx.drawSprite tiles, 13, 4, 0.5, 1
      ctx.drawSprite tiles, 13, 4, 1.5, 1
      ctx.drawSprite tiles, 13, 4, 2.5, 1

      ctx.drawSprite tiles, 13, 4, -0.5, 2
      ctx.drawSprite tiles, 13, 4, 0.5, 2
      ctx.drawSprite tiles, 13, 4, 1.5, 2
      ctx.drawSprite tiles, 13, 4, 2.5, 2

      # Right wall
      ctx.drawSprite tiles, 11, 5, 2.5, 0
      ctx.drawSprite tiles, 11, 6, 2.5, 1

      # Juke juice
      ctx.drawSprite tiles, 12, 4, -0.5, 0

      bp = {x: 0.9, y: 0.84}


      # Ball (red)
      ctx.drawSprite tiles, 14, 0, bp.x, bp.y

      # Flag (blue)
      ctx.drawSprite tiles, 15, 1, bp.x + 0.33, bp.y - 0.82

      canvas.toDataURL (err, url) ->
        throw new Error "Error rendering image" if err

        thumbnailCache[objfiles._id] = url
        callback url

module.exports = mongoose.model "Mod", modSchema
