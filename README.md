# hcclmultinodes
This repository is for HCCL_DEMO on multiple nodes mpirun run.

Usage:
1. setup-hananalab-system.sh to install the SynapseAI SW Stack and dependencies.

2. setup-sshkey-mulnodes.sh to generate SSH Keypair to connect multiple nodes.

3. hccl_demo_mpirun.sh to run HCCL Demo with the following collective operations (all_reduce, all_gather, all2all, reduce_scatter, send_recv).

  You can provide different test_type, test_size, test_loop and host file name. Host file contains ip addresses of all hosts in cluster. The example to run 
  hccl_demo_mpirun.sh:

  ./hccl_demo_mpirun.sh all_reduce 256 4000 myHosts.txt

Results: 
The result files are in the directory of /home/smc/testDepot/HCCL_DEMO/reports/. If the test fails, the result file is empty, otherwise, the result file contains information. for example: smc@smcnode3:~/testDepot/HCCL_DEMO/reports$ ll .hccl-all2all-report .hccl-all_gather-report .hccl-all_reduce-report .hccl-reduce_scatter-report .hccl-send_recv-report.

Logs:
Logs are in the directory of /home/smc/testDepot/HCCL_DEMO/logs/. smc@smcnode3:~/testDepot/HCCL_DEMO/logs$ ll .hccl_s_all2all_dump .hccl_s_all_all_gather_dump .hccl_s_all_gather_dump .hccl_s_all_reduce_dump .hccl_s_reduce_scatter_dump .hccl_s_send_recv_dump.
