---
layout: post
title: 炉石传说之拯救猎人——法术龙鹰猎
author: xfyuan
categories: [Hearthstone]
tags: [life]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img20240106.jpg"
rating: 3
---

*以此文纪念自己独立创建一套炉石传说卡组并验证成功的构思和实践历程，正是一种软件开发者以理性思维解决问题的完美体现 😄*

*【正文如下】*

### 引言

自己唯一到现在都还偶尔玩一下的游戏就只是炉石传说了。一直比较喜欢玩猎人这个职业多一点，打法简单明了，一个字“攻”就完事了，不太喜欢那种需要反复斟酌、仔细衡量的职业，比如牧师。

国服退环境后，在美服开了个账号，年前正式开打。上个月也是凭借猎人上了传说，当时用的是系统推荐的一套奥秘猎稍微修改之后的，某一天突然一路上分异常顺利，可能运气爆棚的缘故，直接就上了传说。

### 构思

这个月想着换个卡组。根据上个月体验，也翻了下 [NGA 炉石传说社区](https://bbs.nga.cn/thread.php?fid=422)各位朋友的各种帖子，综合感觉就是现在天梯上主要就是“德/贼/法”玩家最多，其次算是“骑/术/DK”，别的就很难碰到了。我分析了下这几个常见卡组的特点，以及上个月那套奥秘猎输掉对局的经验，发现最多的劣势发生在如下几种情况：

1. 对方突然搞出几个嘲讽大怪（比如德的那张七费龙，或者贼刷出的某个嘲讽怪，或者骑士的 6 费圣盾怪），猎人那把奥秘加持的 5 攻大刀怎么也砍不到对方脸上；
2. 对方突然掏出吸血怪，还加突袭（比如德的那张 4/12 吸血龙，骑士的吸血光环加持怪），这下猎人不解场就会被对方持续回血，解的话节奏就慢下来，很可能就被对方拖到后期反败为胜。
3. 最后一种就是对方是铺场的卡组（比如树人德，或者DK那种铺场流），奥秘猎除了爆炸陷阱几乎无解场能力，很难打。

所以基于上述三个问题，新的卡组必须能针对性解决，或至少有一搏之力才行。琢磨了两天，最后还真想到了两条对策：

1. 对上面的一和二，采取迂回包围的办法，我不跟你硬拼就好。你不是有嘲讽大墙吗？那我就不过墙一样斩杀。你不是有突袭吸血大怪吗？我不下怪你怎么吸血。
2. 对上面第三种铺场流卡组，就想办法增强抗快攻抵抗力，争取起码有得一拼的能力。

### 卡组

根据上面这个思路，最终组出了一套新的猎人卡组。前面两天尝试和调整，后面三天微调并基本定型，同时一路上分。一路到钻五都很顺利，钻五到传说稍微反复了一下，主要是有两次最后渡劫局都正好被系统安排了新卡组相对来讲还是最劣势的德，都遗憾告负。第三次冲击被安排的是一个挖宝贼，顺利拿下，上传成功！

我给这个卡组取名为“法术龙鹰猎”。下面是我上传的最终版本：

```
### 法术龙鹰猎
# 职业：猎人
# 模式：标准模式
# 独狼年
#
# 2x (1) 坠饰追踪者
# 1x (1) 奥术射击
# 2x (1) 弹溅射击
# 1x (1) 海胆尖刺
# 1x (1) 追踪术
# 2x (2) 咒术之箭
# 2x (2) 泰坦锻造陷阱
# 2x (2) 爆炸陷阱
# 2x (2) 银月城远行者
# 1x (3) 上古海怪杀手
# 2x (3) 星体射击
# 2x (3) 鱼叉炮
# 1x (4) 哈杜伦·明翼
# 2x (4) 哮雷龙鹰
# 2x (4) 明星手枪
# 2x (4) 永歌传送门
# 2x (5) 星辰能量
# 1x (6) 复仇者阿格拉玛
#
AAECAR8GqZ8Eqp8EwbkEwNMEsJIF1/kFDOOfBIPIBKeQBZqSBaqSBaiTBamTBaqkBd/tBfPyBcr2BcGcBgAA
#
# 想要使用这副套牌，请先复制到剪贴板，然后在游戏中点击“新套牌”进行粘贴。
```

### 思路、赢点

核心思路就是前期攒伤害，同时不断用刀蹭对方血量，最后看准时机打出一波高爆发来斩杀。

攒伤害主要通过这几张牌：

- 哮雷龙鹰：这个是最大的爆发点，必须满编。因为它累计没有上限的。所以不能轻易下场，一定是留到最后那一波爆发点。
- 上古海怪杀手：也是个爆发点，只是稍有限制，必须在手牌里后刷满三个法术才会亮起来。一开头带了两张，但后来发现法术量的限制有时候特别卡手，最后只带了一张，感觉正好。
- 银月城远行者 + 哈杜伦·明翼：两个都是加攻的。银月给手牌法术加攻，明翼给所有法术加攻不管在哪，都很重要。但相比起来，银月更优先一些，因为它费用更低（两费），而且打出时手牌里往往都攒的有法术，可以马上生效。明翼就费用太高了点（四费），打出后剩下的费用就不够打出更多法术了。
- 明星手枪 + 奥术射击 + 星体射击：手枪拿来刷奥术射击，又能砍脸蹭血，加上自带的一张（开头也是带了两张，后来改成一张，因为手枪能刷，不差这一张，就腾出位置给其他牌）。奥术射击费用就只一费，攒起来最后一波打出。星体射击加上一堆奥术射击，在上面的“银月 + 明翼”的法伤加成后，伤害总数是很可观的。
- 鱼叉炮：这个其实不算攒伤害的牌，但这里值得提一下，因为它一来攻击力高，3 点攻击蹭血是把好手，二来如果探底能找到“哮雷龙鹰”可以减费，后面爆发时候节省的费用可以打出更多其他法术牌。也算是这套牌不可或缺的组件了。

另外带了五张武器：明星手枪（2）+ 鱼叉炮（2）+ 复仇者阿格拉玛

我们可以把上面这些伤害总成算一算，全部加起来其实是很不少的。举个例子，有一把我在 8 费时候打出这样一波爆发：

- 2 费哮雷龙鹰，8 点伤害（2 费跳币提刀，一直到 8 费都有刀砍出）；
- 1 费奥术射击 2 张，每张 4 点伤害，共 8 点伤害；
- 1 费奥术射击 1 张，3 点伤害；
- 1 费奥术射击 1 张，2 点伤害；
- 2 费猎人技能，2 点伤害；
- 手里还提了“阿格拉玛”的一把 5 攻大刀，5 点伤害

这样就是“9 + 8 + 3 + 2 + 2 + 5”全部一共 29 点伤害一次打出，几乎算是满血斩杀了！（说明：刀先砍，这样哮雷龙鹰实际是 9 点伤害打出）

当然，上面这个例子应该算是特例，实际上往往不需要这样高的爆发就足够斩杀对方了，而且主要靠“哮雷龙鹰 + 上古海怪杀手 + 法伤” 的远距离伤害为主，基本一次打出十几点伤害以上很平常。而这种方式完美绕开了嘲讽怪吸血怪的限制，正是体现了这套卡组的构建思路。

最后说一下对上面第三个问题，即铺场流卡组的对抗。

这是通过下面几张牌来实现的：

- 银月城远行者（2 费） + 星体射击（3 费） + 永歌传送门（4 费）：能够注意到，这三张牌费用正好是 2、3、4 费，而且形成了一个完美的法伤加持链：2 费拍银月，3费 打星体射击，这样 2、3费的“银月 + 星体射击” 总是能解掉一些怪的，所以 4 费打出“永歌传送门”就是四只突袭 4/4 山猫，解场 + 站场一气呵成！铺场流前期往往都是小怪，比如 1/1， 2/2，所以这时候一般都能解干净，然后站着3、4只山猫的场面。接下来就看下一点。
- 星辰能量 + 弹溅射击 + 海胆尖刺：“星辰能量”解场往往都能全部解掉，如果 4 费你有3 、4只山猫站住场了，5 费紧跟星辰再打掉对方的二次铺场，很多时候就大局已定了。毕竟被 3、4只山猫踢脸一次就是 12、16点伤害，剩下血量已在我们斩杀线以内了。而“弹溅射击 + 海胆尖刺”也是解场好手，剧毒解决大怪正是克星。
- 奥秘体系（泰坦锻造陷阱 + 爆炸陷阱）：爆炸陷阱也是前期针对铺场流的好牌，毕竟第一点的（2+3+4）不可能把把上手。泰坦锻造陷阱则是攻守兼备的另一张牌。后者两个奥秘选什么就要根据具体对局来自己衡量了。

### 打法

起手必留“银月城远行者”，这个从上面“思路、赢点”的解读里就可以看出它的重要性。

3 费的“鱼叉炮”，如果不是铺场流就可以留。如果是铺场流，DK都按铺场算，可以留；德，最好不留而是全力去找2+3+4或者奥秘，毕竟树人德前期太凶。

1 费“坠饰追踪者”，我一般必留，1 费不空过很重要，而且还能过一张 1 费法术，很值。

4 费明翼，如果对方是节奏不那么快的卡组，可以考虑留，能够全局加攻还是很重要的。

奥秘的话，泰坦锻造陷阱一般必留，后手一定留，这样 1 费跳币锻造，2 费就可以挂两个奥秘，不管出怪还是其他，都很值。爆炸除非对方是铺场流，否则都不留。

1 费法术，除了“弹溅射击”外，一概不留，因为都可以靠“坠饰追踪者”抽上来。弹溅射击在手，只要被银月或明翼加持一次，就可以解掉对面的 2/2 小怪，还是有用的。

### 对局

- 德：虽然有针对卡牌，还是不算优势对局，毕竟德是设计师亲儿子是众所周知的事实。对于树人德，感觉46开甚至37开了。主要看对方牌顺不顺。关键是它太能铺了，胡起来干掉它一波立马又铺满一波，都不带间隔两个回合的，而且它好几张牌减费都太夸张了（比如 6 费过牌减成 1 费，0 费探底等），往往4、5费能打出太多牌，简直离谱！对于龙德/宇宙德，感觉55开，有得一拼。只要对方的叠甲/补血没有跟上，被我斩杀的不在少数。
- 贼：目前主要就“挖宝/机械”两种流派。对挖宝贼，55开或64开，我最后渡劫局上传就是赢的一个挖宝贼，主要看它挖到啥。如果对方运气太好，要啥来啥，那就很难打了。对机械贼有优势，64开，要点就是不要让它留机械怪在场上。只要不让它站住场，手里一堆贴磁力的小怪就没用了。而上面提到的2+3+4、奥秘、弹溅射击 + 海胆尖刺，都是清场好手。
- DK：对铺场流，优势很大，个人实战体验73开甚至82开的感觉，就没怎么输过。要点就是不要想着打脸，就解它的怪，尽量不要让它站怪超过 2 个，因为它的技能是出一个冲锋1/1怪，这样就有至少有了3个，它再一贴3、4费那两个buff，踢到脸上还是很疼的。如果只剩 1 个怪甚至清场，它一般不会舍得使用 buff。而前期偶尔蹭一下血量，到了7、8费往往我们能一波带走。要注意 8 费它按时拍下那张橙卡，尽量在 8 费或之前斩杀。疫病DK，它通过埋疫病来赢，对比我们还是太慢了点。对局要点就在于前期尽力走脸，刀/伤害尽量落到对方脸上，压低血量。只要运气不是太差，接连抽到对方埋的疫病，也是一般都能8费左右带走。
- 法师：现在基本都是多系法吧，感觉64开。这个对局有两个要点，一是不要让对方站场，因为它手里一堆法术能解掉你的随从，然后它的怪不停踢你脸就很讨厌。二是一定要解掉它的奥术工匠，要不然让它站住了，接下来的回合打一堆法术转眼叠好多甲。基本策略就是“解场 + 蹭血”，最后一把斩杀。
- 骑：不管是决战骑还是土灵骑，都算是偏劣势对局了，还好目前天梯不多。主要是它的圣盾太讨厌，很难一次性解干净，而一旦被它站住了怪，马上buff就贴上来了，确实不太好打。主要策略还是尽量解怪，不让它站住，同时2+3+4在前期如果能打出来，踢到对方脸上，只要对方补血不及时，还是有希望赢的。个人感觉46甚至37开吧。
- 术：好像基本碰到的都是弃牌淤泥术。这个对局主要看对手胡不胡，不顺的话赢它问题不大，策略跟打病DK类似，前期全力输出到脸上，尽量争取在 7 费之前带走，要不然等它凑够了组件，1 血翻盘都有可能。
- 牧、战、萨：目前天梯不多，很少碰上。前两者都挺能加血或者叠甲，是个消耗战，不太容易 10 费前结束战斗。感觉55开吧，输赢都有。萨满碰到的都是图腾萨，优势对局，按铺场流处理就好，而且前期它的图腾都没啥进攻力，解起来不难，73开。

### 实战

最后晒两张渡劫局最后截图吧（我都是在 iPad 上玩，不用电脑，所以没法录像。截图都是最后回合抓紧时间拿手机拍下来的。这是 10 费回合，前面打出 4 费哮雷龙鹰 5点伤害，两张奥术射击共 4点伤害，最后就是截图里这次技能射击 2 点伤害，一共用掉 8 费，还剩 2 费没用，总共打出 11 点伤害。）

![hearthstone_legend_20240106_1](https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/hearthstone_legend_20240106_1.jpg)

![hearthstone_legend_20240106_2](https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/hearthstone_legend_20240106_2.jpg)

![hearthstone_legend_20240106_3](https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/hearthstone_legend_20240106_3.jpg)

最后，我把本文发到 NGA 炉石传说社区上跟其他炉石玩家分享了：

[拯救猎人之美服五日上传——法术龙鹰猎](https://bbs.nga.cn/read.php?tid=38923986&_ff=429)

过了两天，很高兴地看到就有其他玩家就使用这套卡组冲上了传说。开心😄

![08Cj7q](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/08Cj7q.png)