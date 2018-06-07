var fnType = {
  update: function(){
    function getList(){
      var list = [];
      $("#tbl-cate-types tbody tr").each(function(){
        var o = $(this);
        list.push({ type: $("input[name=type_name]",o).val(), order_key: $("input[name=order_key]",o).val() });
      });
      return list;
    }
    function postUpdate(){
      jQuery.post(Routes.update_types_call_categories_path(),Object.add(appl.defaultPostParams(),{ types: getList() }),function(data){
        if(data.errors.length <= 0){
          appl.reloadPage();
        }
      });
    }
    postUpdate();
    console.log(getList());
  },
  
  initForm: function(){
    var iOrderKey = new Cleave('input.order-key',{
      numeral: true,
      numeralPositiveOnly: true
    });
    $("button#btn-update-types").on('click',function(){
      fnType.update();  
    });
  },
  
  init: function(){
    fnType.initForm();
  }
};
jQuery(document).on('ready page:load',function(){ fnType.init(); });