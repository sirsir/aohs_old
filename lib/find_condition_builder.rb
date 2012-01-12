module AMITHAI

   class FindConditionBuilder
      def initialize
         @conditions = []
      end
      def << (condition)
         @conditions << condition
      end
      def build
         all_params = {}
         where_sqls = []
         @conditions.each do |sql, param|
            all_params.update(param)
            where_sqls << sql unless sql.nil? or sql.empty?
         end
         [where_sqls.join(" and "), all_params]
      end
   end

end

