# XIForegroundRepeatsTimer

>创建全局唯一的Timer，通过注册通知的方式分发任务

**适用于：**
1. 只在前台运行，进入后台会自动暂停
2. 灵活控制暂停和启动，动态调整timeInterval
3. 对定时器的准确度要求不高
4. 页面需要刷新的组件多，且独立控制定时刷新任务
5. 不存在强引用目标对象的情况

