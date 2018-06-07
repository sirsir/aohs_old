var fnIndex = {
  init: function(){
    $("a[data-action-name=Download]").on('click',function(){
      appl.noty.info("Maximum transaction to download about 500 records.");
      appl.fileDownload(Routes.download_message_logs_path(jQuery.extend({ format: 'csv' },gon.params)));
      return false;
    });
  }
};
jQuery(document).on('ready page:load',function(){fnIndex.init();});