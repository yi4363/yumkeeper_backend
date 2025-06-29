require "rails_helper"

RSpec.describe "Password Change", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

  # 現在のパスワードを更新
  describe "PUT /api/v1/auth" do
    let(:valid_password) do
      {
        current_password: user.password,
        password: "NewPassword1",
        password_confirmation: "NewPassword1"
      }
    end

    context "送信パスワードと認証情報が正しい場合" do
      it "パスワード更新が成功し、ステータス200が返る" do
        put "/api/v1/auth", params: valid_password, headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["status"]).to eq("success")
      end

      it "DBに保存されているパスワードが更新される" do
        prev_encrypted_password = user.encrypted_password # PUT前のDBに保存されているパスワード

        put "/api/v1/auth", params: valid_password, headers: auth_headers, as: :json

        user.reload
        expect(user.encrypted_password).not_to eq(prev_encrypted_password)
      end
    end

    context "現在のパスワードを送信しない場合" do
      it "パスワード更新が失敗し、ステータス422が返る" do
        put "/api/v1/auth", params: { password: "NewPassword1", password_confirmation: "NewPassword1" }, headers: auth_headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["status"]).to eq("error")
      end
    end

    context "認証情報が正しくない場合" do
      it "ユーザーが見つからず、ステータス404が返る" do
        invalid_headers = {
          "access-token" => "invalid_token",
          "client" => "invalid_client",
          "uid" => "invalid_uid@example.com"
        }

        put "/api/v1/auth", params: valid_password, headers: invalid_headers, as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["errors"]).to include("ユーザーが見つかりません。")
      end
    end
  end
end
