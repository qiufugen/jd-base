#!/bin/sh

## 修改日期：2020-11-10
## 作者：Evine Deng <evinedeng@foxmail.com>

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LC_ALL=C

RootDir=$(cd $(dirname $0); pwd)
ShellDir="${RootDir}/shell"
LogDir="${RootDir}/log"
ScriptsDir="${RootDir}/scripts"
isDocker=$(cat /proc/1/cgroup | grep docker)

cd ${RootDir}

## 尝试自动恢复任务，如文件夹不存在则尝试克隆
if [ -d ${ScriptsDir} ] && [ -d ${ShellDir} ] && [ -f ${RootDir}/crontab.list ] && [ -n "${isDocker}" ]
then
  echo -e "检测到本机为容器，并且${ScriptsDir}、${ShellDir}、${RootDir}/crontab.list均存在，开始自动恢复定时任务...\n"
  crontab ${RootDir}/crontab.list
  echo -e "当前的定时任务如下：\n"
  crontab -l
  echo ""
elif [ -d ${ScriptsDir} ] && [ -d ${ShellDir} ] && [ -f ${RootDir}/crontab.list ] && [ -z "${isDocker}" ]
then
  echo -e "检测到本机为物理机，虽然${ScriptsDir}、${ShellDir}、${RootDir}/crontab.list均存在...\n但为防止破坏物理机上本身已经存在的定时任务，跳过恢复定时任务，请手动添加...\n"
else
  if [ ! -d ${ScriptsDir} ]; then
    echo -e "${ScriptsDir} 目录不存在，开始克隆...\n"
    git clone https://github.com/lxk0301/jd_scripts scripts
    echo
  fi
  
  if [ ! -d ${ShellDir} ]; then
    echo -e "${ShellDir} 目录不存在，开始克隆...\n"
    git clone https://github.com/EvineDeng/jd-base shell
    echo
  fi
fi

## 读取 ${ScriptsDir}/docker/crontab_list.sh 中的 js 脚本定时任务为初始任务清单
if [ -f ${ScriptsDir}/docker/crontab_list.sh ]; then
  JsList=$(cat ${ScriptsDir}/docker/crontab_list.sh | grep -E "jd_.+\.js" | awk -F " " '{print $7}' | sed "{s|/scripts/||;s|\.js||}")
fi

## 创建初始日志目录
if [ -n "${JsList}" ]
then
  for Task in ${JsList}; do
    if [ ! -d ${LogDir}/${Task} ]
    then
      echo -e "创建 ${LogDir}/${Task} 日志目录...\n"
      mkdir -p ${LogDir}/${Task}
    else 
      echo -e "日志目录 ${LogDir}/${Task} 已存在，跳过创建...\n"
    fi
  done
else
  if [ -z "${isDocker}" ]
  then
    echo -e "${ScriptsDir}/docker/crontab_list.sh 不存在，可能是 js 脚本克隆不正常，请删除 ${ScriptsDir} 文件夹后重新运行本脚本...\n"
  else
    echo -e "${ScriptsDir}/docker/crontab_list.sh 不存在，可能是 js 脚本克隆不正常，请删除 ${ScriptsDir} 文件夹后重新启动容器...\n"
  fi
fi

## 复制初始任务脚本
if [ -s ${ShellDir}/jd.sh.sample ]
then
  if [ -n "${JsList}" ]; then
    for Task in ${JsList}; do
      cp -fv "${ShellDir}/jd.sh.sample" "${ShellDir}/${Task}.sh"
      chmod +x "${ShellDir}/${Task}.sh"
      echo
    done
    echo -e "脚本执行成功，请按照 Readme 教程继续配置..."
  fi
else
  if [ -z "${isDocker}" ]
  then
    echo -e "${ShellDir}/jd.sh.sample 不存在或内容为空，可能是 shell 脚本克隆不正常，请删除 ${ShellDir} 文件夹后重新运行本脚本...\n"
  else
    echo -e "${ShellDir}/jd.sh.sample 不存在或内容为空，可能是 shell 脚本克隆不正常，请删除 ${ShellDir} 文件夹后重新启动容器...\n"
  fi
fi

