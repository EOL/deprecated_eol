class UsersDataObjectsRating < ActiveRecord::Base
  belongs_to :user
  belongs_to :data_object

  # This is used by Tramea:
  def self.params_from_data_object(dato)
    ratings = dato.rating_summary
    {
      ratings_1: ratings[1],
      ratings_2: ratings[2],
      ratings_3: ratings[3],
      ratings_4: ratings[4],
      ratings_5: ratings[5],
      rating_weighted_average: dato.average_rating
    }
  end
end
