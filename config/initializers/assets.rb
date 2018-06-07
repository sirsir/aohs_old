# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.

# all files in assets directory
Rails.application.config.assets.precompile += ['*.js']
Rails.application.config.assets.precompile += ['*.css','*.scss']
Rails.application.config.assets.precompile += ['*.woff','*.ttf','*.eot','*.swf']

Rails.application.config.assets.precompile += ['*.gif','*.png','*.jpeg']

# see asset path
# STDOUT.puts Rails.application.config.assets.paths 