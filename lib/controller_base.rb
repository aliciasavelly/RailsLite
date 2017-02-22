require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res)
    @req = req
    @res = res
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise if already_built_response?
    @res["Location"] = url
    @res.status = 302
    @already_built_response = true
    @session.store_session(@res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise if already_built_response?
    @res.write(content)
    @res['Content-Type'] = content_type
    @already_built_response = true
    @session.store_session(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller_name = self.class.to_s.underscore
    content = File.read("../views/#{controller_name}/#{template_name}.html.erb")
    raise if already_built_response?
    render_content(ERB.new(content).result(binding), 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    ## ?? note why self? what's self?
    ## self is the controller here, whatever controller is being used so
    ## could be the cats controller because it inherits. why do we
    ## use self here if we want to call it on the router?
    self.send(name)
    render name unless already_built_response?

    nil
  end
end
