class Testcase < ApplicationRecord
  belongs_to :problem
  has_many :testcase_testcase_sets, dependent: :destroy
  has_many :testcase_results, dependent: :destroy
  has_many :testcase_sets, through: :testcase_testcase_sets
  before_destroy :destroy_data

  def input_data=(input_data)
    Utils::GoogleCloudStorageClient.upload_input(self.problem.uuid, self.name, input_data)
  end

  def output_data=(output_data)
    Utils::GoogleCloudStorageClient.upload_output(self.problem.uuid, self.name, output_data)
  end

  def destroy_data
    Utils::GoogleCloudStorageClient.delete_testcase(self.problem.uuid, self.name)
  end

  def input_data(is_sample = false)
    if self.input
      self.input
    else
      ret = Utils::GoogleCloudStorageClient.get_input(self.problem.uuid, self.name)
      if is_sample && ret.bytesize < 1024
        self.input = ret
        self.save!
      end
      ret
    end
  end

  def output_data(is_sample = false)
    if self.output
      self.output
    else
      ret = Utils::GoogleCloudStorageClient.get_output(self.problem.uuid, self.name)
      if is_sample && ret.bytesize < 1024
        self.output = ret
        self.save!
      end
      ret
    end
  end
end
