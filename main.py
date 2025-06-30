from mcp.server.fastmcp import FastMCP
import requests
from datetime import datetime
import json
import logging

# Logger 설정
logger = logging.getLogger("hyteria_menu")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
formatter = logging.Formatter('[%(asctime)s] %(levelname)s - %(message)s')
handler.setFormatter(formatter)
if not logger.hasHandlers():
    logger.addHandler(handler)

mcp = FastMCP("hyteria")
mcp.settings.host = "0.0.0.0"
#mcp.settings.message_path = "/hyteria-mcp/messages/"

@mcp.tool()
def get_hyeteria_menu_info(query: str) -> str:
    """오늘 하이테리아 메뉴를 가져옵니다."""
    source = "hyteria"
    today = datetime.now().strftime('%Y%m%d')
    logger.info(f"하이테리아 메뉴 조회 시도: {today}")

    def fetch_menu_data(date):
        url = f"https://mc.skhystec.com/V3/prc/selectMenuList.prc?campus=BD&cafeteriaSeq=21&mealType=LN&ymd={date}"
        try:
            response = requests.post(url, verify=False, timeout=5)
            if response.status_code == 200:
                data = response.json()
                print(data)
                if data.get("RESULT") == 'N':
                    logger.warning(f"메뉴 데이터 없음: {date}")
                    return None
                menu_data = {"date": datetime.strptime(date, '%Y%m%d').strftime("%Y-%m-%d"), "body": data, "source": source}
                logger.info(f"메뉴 데이터 성공적으로 수신: {date}")
                return menu_data
            else:
                logger.error(f"HTTP 오류: {response.status_code} - {date}")
                return None
        except Exception as e:
            logger.exception(f"예외 발생: {e}")
            return None

    menu = fetch_menu_data(today)
    if not menu or not menu["body"] or not menu["body"].get("menuList"):
        logger.error("오늘의 하이테리아 메뉴 정보를 불러올 수 없습니다.")
        return "오늘의 하이테리아 메뉴 정보를 불러올 수 없습니다."

    menu_list = menu["body"]["menuList"]
    if not menu_list:
        logger.warning("오늘의 하이테리아 메뉴가 없습니다.")
        return "오늘의 하이테리아 메뉴가 없습니다."

    result = f"📅 {menu['date']} 하이테리아 메뉴\n\n"
    for i, item in enumerate(menu_list, 1):
        menu_name = item.get("MENU_NAME", "메뉴명 없음")
        course_name = item.get("COURSE_NAME", "코스명 없음")
        if course_name == "":
            course_name = "기타"
        result += f". {course_name} \n"
        result += f"  - {menu_name} \n"
    logger.info("메뉴 정보 반환 완료")
    return result


if __name__ == "__main__":
    mcp.run(transport="sse", mount_path="/hyteria-mcp")
