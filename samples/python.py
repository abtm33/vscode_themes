# 苫小牧

# パッケージ、モジュールのインポート
import datetime
import os
from time import sleep
import json
import pickle
import pandas as pd
import funcs_suumo as suumo


# 準備 =============================================

# 対象地名
res_name = "kawagoeshi"
res_name_jp = "川越市駅"

path_current = os.path.dirname(__file__)

# 検索ページURLの指定
path_url = os.path.join(path_current, "../../data/in/stations.json")
stations = open(path_url, "r")
stations = json.load(stations)
url_search = stations[res_name_jp]["url"]

# 取得日
today = datetime.date.today()
today = str(today)

# 保存ファイル名
filename = res_name + "_" + today


# 取得 ===================================================
# 検索結果ページから、個別物件のリンクを一通り取得
res_search = suumo.tour_search_result(search_url=url_search, silent=False)

# 保存
os.makedirs("../../data/search_res_pickles", exist_ok=True)
property_draft_data = "../../data/search_res_pickles/" + filename + ".pickle"
with open(property_draft_data, mode="wb") as f:
    pickle.dump(res_search, f)


# 各物件のリンク先から情報を取得し、辞書のリストに格納
list_all_bld = []
list_fail = []
for i, building in enumerate(res_search):
    print("FETCHING " + str(i) + " in " + str(len(res_search)))
    print(building)
    try:
        bld_df = suumo.fetch_building_allinfo(building, return_df=False)
        list_all_bld += bld_df
    except:
        print("Failed fetching building info.")
        list_fail.append(building)

path_fail = "../../data/fetched/" + filename + "_fail.pickle"
with open(path_fail, mode="wb") as f:
    pickle.dump(list_fail, f)

# データフレームにする
df_res = pd.DataFrame(list_all_bld)

# 保存
os.makedirs("../../data/fetched", exist_ok=True)
path_save = "../../data/fetched/" + filename + ".csv"
df_res.to_csv(path_save, sep=",", encoding="utf-8-sig")
print(path_save + "saved.")
