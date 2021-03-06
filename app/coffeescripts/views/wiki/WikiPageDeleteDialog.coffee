define [
  'jquery'
  'underscore'
  'i18n!pages'
  'str/htmlEscape'
  'compiled/views/DialogFormView'
], ($, _, I18n, htmlEscape, DialogFormView) ->

  dialogDefaults =
    fixDialogButtons: false
    title: I18n.t 'delete_dialog_title', 'Delete Wiki Page'
    width: 400
    height: 'auto'

  class WikiPageDeleteDialog extends DialogFormView
    setViewProperties: false
    wrapperTemplate: -> '<div class="outlet"></div>'
    template: ->
      if (ENV["COURSE_ID"] == 1) 
        'Warning: deleting this page or assignment will also delete it from any course that uses it from the Content Library'
      else
        I18n.t('delete_confirmation', 'Are you sure you wish to delete this wiki page?')

    @optionProperty 'wiki_pages_path'
    @optionProperty 'focusOnCancel'
    @optionProperty 'focusOnDelete'

    initialize: (options) ->
      super _.extend {}, dialogDefaults, options

    submit: (event) ->
      event?.preventDefault()

      destroyDfd = @model.destroy(wait: true)

      dfd = $.Deferred()
      page_title = @model.get('title')
      wiki_pages_path = @wiki_pages_path

      destroyDfd.then =>
        if wiki_pages_path
          expires = new Date
          expires.setMinutes(expires.getMinutes() + 1)
          path = '/' # should be wiki_pages_path, but IE will only allow *sub*directries to read the cookie, not the directory itself...
          $.cookie 'deleted_page_title', page_title, expires: expires, path: path
          window.location.href = wiki_pages_path
        else
          $.flashMessage I18n.t 'notices.page_deleted', 'The page "%{title}" has been deleted.', title: page_title
          dfd.resolve()
          @close()

      destroyDfd.fail =>
        $.flashError I18n.t('notices.delete_failed', 'The page "%{title}" could not be deleted.', title: page_title)
        dfd.reject()

      @$el.disableWhileLoading dfd

    setupDialog: ->
      super

      form = @

      # Add a close event for focus handling
      form.$el.on('dialogclose', (event, ui) =>
        @focusOnCancel?.focus()
      )

      buttons = [
        class: 'btn'
        text: I18n.t 'cancel_button', 'Cancel'
        click: =>
          form.$el.dialog 'close'
      ,
        class: 'btn btn-danger'
        text: I18n.t 'delete_button', 'Delete'
        'data-text-while-loading': I18n.t 'deleting_button', 'Deleting...'
        click: =>
          form.submit()
          @focusOnDelete.focus()
      ]
      @$el.dialog 'option', 'buttons', buttons
