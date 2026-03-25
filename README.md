# Multiple Queues (MQ)

This repository contains the FPGA implementation of the Multiple Queues (MQ) architecture presented in our paper:

> Designing Multiple Queues to Support Asynchronous Traffic Shaping in Shared-Buffer TSN Switches
> (IEEE TCAD 2026)

MQ realizes Asynchronous Traffic Shaping (ATS) queues as metadata-driven logical queues on top of a shared-buffer switch architecture.

## Key Features

- Virtual queues implemented with lightweight head/tail pointers
- Centralized Multiple Queues Manager for enqueue/dequeue control
- Shift-register–based scheduler
- Full compatibility with IEEE 802.1Qcr ATS eligibility time computation

## Architecture

<figure>
  <img src="image/Design overview.svg" alt="MQ architecture overview on a shared-buffer switch" width="600">
  <figcaption>Figure 1. Design overview.</figcaption>
</figure>

<figure>
  <img src="image/MQ planes structure.svg" alt="Structure of MQ planes" width="600">
  <figcaption>Figure 2. MQ planes structure.</figcaption>
</figure>

## License

Released under the MIT License.

## References

```bibtex
@ARTICLE{11455258,
  author={Wu, Wenxue and Zhang, Tong and Li, Zhen and Zhang, Liwei and Yang, Hao and Ren, Fengyuan},
  journal={IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems}, 
  title={Designing Multiple Queues to Support Asynchronous Traffic Shaping in TSN Switches}, 
  year={2026},
  volume={},
  number={},
  pages={1-1},
  keywords={Time-Sensitive Networking;Multiple Queues;Asynchronous Traffic Shaping;Shared Buffer Switch},
  doi={10.1109/TCAD.2026.3677291}}

```

