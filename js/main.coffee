---
---

$ ->
  if window?.location?.hash is "#blog"
    $('.panel-cover').addClass('panel-cover--collapsed')
    $('.main-post-list').removeClass('hidden')

  if window?.location?.pathname.substring(0, 5) is "/tag/"
    $('.panel-cover').addClass('panel-cover--collapsed')

  # ========================================================================
  # ========================================================================

  $('a.blog-button').click ->
    # If already in blog, return early without animate overlay panel again.
    return if location?.hash is "#blog"
    return if $('.panel-cover').hasClass('panel-cover--collapsed')
    $('.main-post-list').removeClass('hidden')
    currentWidth = $('.panel-cover').width()
    if currentWidth < 960
      $('.panel-cover').addClass('panel-cover--collapsed')
    else
      $('.panel-cover').css('max-width',currentWidth).animate({'max-width': '700px', 'width': '30%'}, 400, swing = 'swing')

  $('.btn-mobile-menu__icon').click ->
    $('.btn-mobile-menu__icon').toggleClass('fa fa-list fa fa-angle-up animated fadeIn')
    if $('.navigation-wrapper').css('display') is "block"
      $('.navigation-wrapper').on 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', ->
        $('.navigation-wrapper').toggleClass('visible animated bounceOutUp').off('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend')
      $('.navigation-wrapper').toggleClass('animated bounceInDown animated bounceOutUp')
    else
      $('.navigation-wrapper').toggleClass('visible animated bounceInDown')

  $('.navigation-wrapper .blog-button').click ->
    $('.btn-mobile-menu__icon').toggleClass('fa fa-list fa fa-angle-up animated fadeIn')
    if $('.navigation-wrapper').css('display') is "block"
      $('.navigation-wrapper').on 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', ->
        $('.navigation-wrapper').toggleClass('visible animated bounceOutUp').off('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend')
      $('.navigation-wrapper').toggleClass('animated bounceInDown animated bounceOutUp')

